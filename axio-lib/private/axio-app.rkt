#lang racket/base

(require "axio-config.rkt"
         "axio-init-structs.rkt"
         "axio-init.rkt"
         "axio-session.rkt"
         "axio-view.rkt"
         "axio-web-ctx.rkt"
         "axio-web-utilities.rkt")

(require (prefix-in lift: web-server/dispatchers/dispatch-lift)
         (prefix-in log:  web-server/dispatchers/dispatch-log)
         (prefix-in seq:  web-server/dispatchers/dispatch-sequencer)
         racket/contract
         web-server/web-server)

(provide (contract-out
          [ axio-app-init
            (->* (axio-config? procedure? procedure?)
                 (#:db   (or/c axio-db-config? #f)
                  #:smtp (or/c axio-smtp-config? #f)
                  #:exception-handler (or/c procedure? #f))
                 any) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-app-init config route url-for
                       #:db [ db #f ]
                       #:smtp [ smtp #f ]
                       #:exception-handler [ exception-handler #f ])
  (let* ([ axio-context (axio-init config
                                   #:db-config db
                                   #:smtp-config smtp) ]
         [ instance-id  (string->number (vector-ref (current-command-line-arguments) 0)) ]
         [ port         (+ (axio-config-port-base config) instance-id)                   ]
         )
    (void
     (serve
      #:dispatch (seq:make (log:make #:format log:extended-format
                                     #:log-path "axio-app.log")
                           (lift:make (λ (request)
                                        (front-controller axio-context
                                                          request
                                                          route
                                                          url-for
                                                          exception-handler))))
      #:port port))

    (do-not-return)))

;; --------------------------------------------------------------------------------------------
;; Private Implementation
;; --------------------------------------------------------------------------------------------

#;(define (logged-in-user conn session)
  (and session
       (let ([ userid (hash-ref session 'userid #f) ])
         (and userid
              (integer? userid)
              (get-user conn userid)))))

(define (front-controller axioctx request route url-for exception-handler)
  (define conn    (axio-context-db-conn axioctx))
  (define session (get-session request conn))

  (define (run)
    (define (handle-exception e)
      (cond [ exception-handler
              (exception-handler e) ]
            [ else
              ((error-display-handler) (exn-message e) e)
              (render-string "<html><body>An error has occurred</body></html>") ]))

    (with-handlers ([ exn:fail? handle-exception ])
      (let* ([ ctx (build-webctx request
                                 (form-values request)
                                 session
                                 conn
                                 axioctx
                                 url-for
                                 (hash)) ])
        (route ctx))))

  (dynamic-wind void
                run
                void))
