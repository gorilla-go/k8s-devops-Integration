package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/go-openapi/strfmt"
	"github.com/gorilla-go/pig"
)

type PostableAlert struct {
	// annotations
	Annotations  map[string]string `json:"annotations,omitempty"`
	EndsAt       strfmt.DateTime   `json:"endsAt,omitempty"`
	StartsAt     strfmt.DateTime   `json:"startsAt,omitempty"`
	GeneratorURL strfmt.URI        `json:"generatorURL,omitempty"`
	Labels       map[string]string `json:"labels"`
}

type FluentBitMessageItem struct {
	Date   float32 `json:"date"`
	Log    string  `json:"log"`
	Source string  `json:"source"`
}

func main() {
	host := flag.String("host", "alertmanager", "alertmanager host name")
	port := flag.Int("port", 9093, "alertmanager port")
	uri := flag.String("uri", "/api/v2/alerts", "alertmanager uri")
	isHttps := flag.Bool("https", false, "http or https")
	debug := flag.Bool("debug", false, "debug mode.")
	sep := flag.String("sep", "\n", "sep")
	flag.Parse()

	protocol := "http"
	if *isHttps {
		protocol = "https"
	}
	path := fmt.Sprintf("%s://%s:%d%s", protocol, *host, *port, *uri)

	// handle queue.
	messageChan := make(chan FluentBitMessageItem, 1024*1024)
	go func() {
		prepareMessageMap := map[string]string{}
		timer := time.NewTimer(time.Second * 10)
		defer timer.Stop()

		for {
			timer.Reset(time.Second * 10)
			select {
			case message := <-messageChan:
				prepareMessageMap[message.Source] = prepareMessageMap[message.Source] + message.Log + *sep
				continue
			case <-timer.C:
				if len(prepareMessageMap) != 0 {
					alerts := []PostableAlert{}
					for source, message := range prepareMessageMap {
						// send message
						postableAlert := PostableAlert{
							Labels: map[string]string{
								"alertname": "A new error from " + source,
								"severity":  "critical",
								"job":       "error-reporter",
							},
							StartsAt: strfmt.DateTime(time.Now()),
							Annotations: map[string]string{
								"description": message,
							},
						}
						alerts = append(alerts, postableAlert)
						delete(prepareMessageMap, source)
					}
					alertsJson, err := json.Marshal(alerts)
					if err != nil {
						panic(err)
					}

					response, err := http.Post(path, "application/json", bytes.NewBuffer(alertsJson))
					if err != nil {
						fmt.Println(err.Error())
						continue
					}

					if *debug {
						fmt.Println("-------------- debug --------------")
						fmt.Println(string(alertsJson))
					}

					if response.StatusCode >= 200 && response.StatusCode < 300 {
						prepareMessageMap = map[string]string{}
						continue
					}

					body, _ := io.ReadAll(response.Body)
					fmt.Println(body)
				}
			}
		}
	}()

	r := pig.NewRouter()

	r.GET("/-/healthz", func(ctx *pig.Context) {
		ctx.Response().Code(200)
	})

	r.GET("/-/readiness", func(ctx *pig.Context) {
		ctx.Response().Code(200)
	})

	r.POST("/alert", func(ctx *pig.Context) {
		defer func() {
			if r := recover(); r != nil {
				if *debug {
					fmt.Println(r)
				}
				ctx.Response().Code(400)
			}
		}()
		fluentBitMessageArr := make([]FluentBitMessageItem, 0)
		ctx.Request().JsonBind(&fluentBitMessageArr)
		for _, fluentBitMessage := range fluentBitMessageArr {
			messageChan <- fluentBitMessage
		}
		ctx.Response().Code(200)
	})

	pig.New().Router(r).Run(8081)
}
