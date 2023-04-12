package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		fmt.Printf("Message ID: %s\n", message.MessageId)
		fmt.Printf("Event Source: %s\n", message.EventSource)
		fmt.Printf("Body: %s\n", message.Body)
	}
	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
