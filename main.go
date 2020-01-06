package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"

	"github.com/jordan-wright/email"
	"github.com/prometheus/alertmanager/template"
	gmail "google.golang.org/api/gmail/v1"
	"google.golang.org/api/option"
)

type responseJSON struct {
	Status  int
	Message string
}

func asJSON(w http.ResponseWriter, status int, message string) {
	data := responseJSON{
		Status:  status,
		Message: message,
	}
	bytes, _ := json.Marshal(data)
	json := string(bytes[:])

	w.WriteHeader(status)
	fmt.Fprint(w, json)
}

func logSend(a template.Alert, r *http.Request) {
	log.Printf("alert: %s\r\n", a)
}

func logging(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, err := ioutil.ReadAll(r.Body)
		if err != nil {
			panic(err)
		}
		body := ioutil.NopCloser(bytes.NewBuffer(b))
		logRawRequest(r)
		r.Body = body
		h.ServeHTTP(w, r)
	})
}

func logRawRequest(r *http.Request) {
	b, _ := ioutil.ReadAll(r.Body)
	var buf bytes.Buffer
	if err := json.Indent(&buf, b, "", "  "); err != nil {
		log.Printf("error parsing json: %s", err.Error())
	}
	log.Println("\n" + buf.String())
}

func gmailSend(alert template.Alert) {
	log.Printf("sending gmail...")
	svr, err := getGmailService()
	if err != nil {
		log.Fatalf("Unable to get Gmail service: %v", err)
	}
	var message gmail.Message
	reg := regexp.MustCompile("\\s*,\\s*")
	e := email.NewEmail()
	e.From = os.Getenv("GMAIL_FROM")
	e.To = reg.Split(alert.Annotations["emails"], -1)
	e.ReplyTo = reg.Split("no-reply@gmail.com", -1)
	e.Subject = "Prometheus Alert Email Notification"
	e.Text = []byte(alert.Annotations["summary"])
	rawText, err := e.Bytes()
	if err != nil {
		log.Printf("error to convert into bytes: %v", err)
		return
	}
	log.Printf("email rawText: %s\r\n", rawText)
	message.Raw = base64.URLEncoding.EncodeToString(rawText)
	user := "me"

	_, err = svr.Users.Messages.Send(user, &message).Do()
	if err != nil {
		// log.Printf("Error sending gmail: %v", err)
		log.Fatalf("Error sending gmail: %v", err)
	}
	r, err := svr.Users.Labels.List(user).Do()
	if err != nil {
		log.Fatalf("Unable to retrieve labels: %v", err)
	}
	if len(r.Labels) == 0 {
		fmt.Println("No labels found.")
		return
	}
	fmt.Println("Labels:")
	for _, l := range r.Labels {
		fmt.Printf("- %s\n", l.Name)
	}
}

// Request a token from the web, then returns the retrieved token.
func getTokenFromWeb(config *oauth2.Config) *oauth2.Token {
	authURL := config.AuthCodeURL("state-token", oauth2.AccessTypeOffline)
	fmt.Printf("Go to the following link in your browser then type the "+
		"authorization code: \n%v\n", authURL)

	var authCode string
	if _, err := fmt.Scan(&authCode); err != nil {
		log.Fatalf("Unable to read authorization code: %v", err)
	}

	tok, err := config.Exchange(context.TODO(), authCode)
	if err != nil {
		log.Fatalf("Unable to retrieve token from web: %v", err)
	}
	return tok
}

func getGmailService() (*gmail.Service, error) {
	clientSecretFile := "config/client_secret.json"
	tokenFile := "config/token.json"

	b, err := ioutil.ReadFile(clientSecretFile)
	if err != nil {
		log.Printf("Unable to read client secret file: %v", err)
		return nil, err
	}

	config, err := google.ConfigFromJSON(b, gmail.MailGoogleComScope)
	if err != nil {
		log.Printf("Unable to parse client secret file to config: %v", err)
		return nil, err
	}

	//read token from file,
	f, err := os.Open(tokenFile)
	defer f.Close()
	if err != nil {
		log.Printf("Unable to get token file: %v", err)
		return nil, err
	}

	token := &oauth2.Token{}
	err = json.NewDecoder(f).Decode(token)
	if err != nil {
		log.Printf("Unable to get token. %v", err)
		return nil, err
	}

	// client := config.Client(context.Background(), token)
	ctx := context.Background()
	gmailService, err := gmail.NewService(ctx,
		option.WithTokenSource(config.TokenSource(ctx, token)))
	if err != nil {
		log.Printf("Unable to inititate gmailService. %v", err)
		return nil, err
	}

	return gmailService, nil
}

func webhook(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	data := template.Data{}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		asJSON(w, http.StatusBadRequest, err.Error())
		return
	}
	log.Printf("Alerts: GroupLabels=%v, CommonLabels=%v", data.GroupLabels, data.CommonLabels)
	for _, alert := range data.Alerts {
		log.Printf("Alert: status=%s,Labels=%v,Annotations=%v", alert.Status, alert.Labels, alert.Annotations)
		severity := alert.Labels["severity"]
		switch strings.ToUpper(severity) {
		case "CRITICAL":
			gmailSend(alert)
		case "NONE":
			logSend(alert, r)
		default:
			log.Printf("no action on severity: %s\n", severity)
		}
	}
	asJSON(w, http.StatusOK, "success")
}

func healthz(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "Ok!")
}

func main() {
	webhookFunc := http.HandlerFunc(webhook)
	http.HandleFunc("/healthz", healthz)
	http.Handle("/webhook", logging(webhookFunc))

	listenAddress := ":8080"
	if os.Getenv("PORT") != "" {
		listenAddress = ":" + os.Getenv("PORT")
	}

	log.Printf("listening on: %v", listenAddress)
	log.Fatal(http.ListenAndServe(listenAddress, nil))
}
