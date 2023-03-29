#lang racket/base

(require racket/contract
         racket/match)

(provide (contract-out
          [ axio-init-logger (-> symbol? any)              ]
          [ axio-log-debug   (->* (string?) (symbol?) any) ]
          [ axio-log-error   (->* (string?) (symbol?) any) ]
          [ axio-log-fatal   (->* (string?) (symbol?) any) ]
          [ axio-log-info    (->* (string?) (symbol?) any) ]
          [ axio-log-receiver
            (-> symbol? symbol? (-> symbol? string? any/c symbol? any) any) ]
          [ axio-log-warning (->* (string?) (symbol?) any) ]
          [ axio-logger      (-> logger?)                  ]
          [ axio-logger-from-symbol
            (-> symbol? any) ]))

(define logger #f)

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-init-logger level)
  (set! logger (make-logger 'axio))

  (axio-log-receiver
   level
   'axio
   (λ (level message data topic)
     (printf "level:~a topic:~a message:~a\n" level topic message)
     (flush-output))))

(define (axio-log-debug str [topic 'axio]) (log-message logger 'debug topic str #f #f))
(define (axio-log-error str [topic 'axio]) (log-message logger 'error topic str #f #f))
(define (axio-log-fatal str [topic 'axio]) (log-message logger 'fatal topic str #f #f))
(define (axio-log-info str [topic 'axio])  (log-message logger 'info topic str #f #f))

(define (axio-log-receiver level topic proc)
  (define log-receiver (make-log-receiver logger level topic))

  (void
   (thread
    (λ ()
      (let loop ()
        (match (sync log-receiver)
          [(vector level message data topic) (proc level message data topic)])
        (loop))))))

(define (axio-log-warning str [topic 'axio]) (log-message logger 'warning topic str #f #f))
(define (axio-logger)                        logger)

(define (axio-logger-from-symbol sym)
  (match sym
    [ 'debug   axio-log-debug   ]
    [ 'error   axio-log-error   ]
    [ 'fatal   axio-log-fatal   ]
    [ 'info    axio-log-info    ]
    [ 'warning axio-log-warning ]))
