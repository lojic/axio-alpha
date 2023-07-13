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
      (when (axio-smtp-config-server smtp-config)
        (smtp-send-message (axio-smtp-config-server smtp-config)
                           from
                           to
                           (standard-message-header from to '() '() subject)
                           message-lines
                           #:port-no     (axio-smtp-config-port smtp-config)
                           #:auth-user   (axio-smtp-config-username smtp-config)
                           #:auth-passwd (axio-smtp-config-password smtp-config)
                           #:tls-encode  ssl-encoder)))
    #f))

;; This wrapper is required to allow specifying 'tls12 to ports->ssl-ports
(define (ssl-encoder r w #:mode mode #:encrypt enc #:close-original? close?)
  (ports->ssl-ports r w #:mode mode #:encrypt 'tls12 #:close-original? close?))

;; main module to test email configuration
#;(module+ main
  (send-email "Fred Flintstone <brian@lojic.com>"
              '("Barney Rubble <register@lojic.com>")
              "Test message subject"
              (list
               "Message line one"
               "line two"
               ""
               "line four")))
