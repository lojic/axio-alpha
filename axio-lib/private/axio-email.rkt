#lang racket/base

(require "./axio-config.rkt")

(require net/head
         net/smtp
         openssl
         racket/contract)

(provide (contract-out
          [ send-email
            (-> string? (listof string?) string? (listof (or/c string? bytes?)) any) ]))

;; Send an email. Returns #f if successful; otherwise, returns the exception message.
(define (send-email from to subject message-lines)
  (define (format-error e)
    (format "from=~a, to=~a, subject=~a, error=~a"
            from to subject (exn-message e)))
  (with-handlers ([ exn:fail? format-error ])
    (let ([ smtp-config (get-axio-smtp-config) ])
      (smtp-send-message (axio-smtp-config-server smtp-config)
                         from
                         to
                         (standard-message-header from to '() '() subject)
                         message-lines
                         #:port-no     (axio-smtp-config-port smtp-config)
                         #:auth-user   (axio-smtp-config-username smtp-config)
                         #:auth-passwd (axio-smtp-config-password smtp-config)
                         #:tls-encode  ports->ssl-ports))
    #f))

;; main module to test email configuration
#;(module+ main
  (send-email "Fred Flintstone <fred@example.com>"
              '("Barney Rubble <barney@example.com>")
              "Test message subject"
              (list
               "Message line one"
               "line two"
               ""
               "line four")))
