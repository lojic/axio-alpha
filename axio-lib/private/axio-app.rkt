#lang racket/base

(require "axio-authentication.rkt"
         "axio-config.rkt"
         "axio-controller.rkt"
         "axio-crypto.rkt"
         "axio-database.rkt"
         "axio-email.rkt"
         "axio-init-structs.rkt"
         "axio-init.rkt"
         "axio-logger.rkt"
         "axio-regex.rkt"
         "axio-serialize.rkt"
         "axio-session.rkt"
         "axio-string.rkt"
         "axio-validation.rkt"
         "axio-view.rkt"
         "axio-web-ctx.rkt"
         "axio-web-utilities.rkt"
         "axio-worker.rkt")

(require (prefix-in lift: web-server/dispatchers/dispatch-lift)
         (prefix-in log:  web-server/dispatchers/dispatch-log)
         (prefix-in seq:  web-server/dispatchers/dispatch-sequencer)
         racket/contract
         web-server/web-server)

(provide (contract-out
          [ axio-app-init
            (->* (axio-config? procedure?)
                 (#:db   (or/c axio-db-config? #f)
                  #:smtp (or/c axio-smtp-config? #f))
                 any) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-app-init config route #:db [ db #f ] #:smtp [ smtp #f ])
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
                                        (front-controller axio-context request route))))
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

(define (front-controller axioctx request route)
  (define conn    (axio-context-db-conn axioctx))
  (define session (get-session request conn))

  (define (run)
    (define (handle-exception e)
      ((error-display-handler) (exn-message e) e)
      ;; TODO allow user to specify error response e.g. HTML vs. JSON
      (render-string "{ \"errors\" : [\"internal error\"] }"))

    (with-handlers ([ exn:fail? handle-exception ])
      (let* ([ ctx (build-webctx request
                                 (form-values request)
                                 session
                                 conn
                                 axioctx) ])
        (route ctx))))

  (dynamic-wind void
                run
                void))
