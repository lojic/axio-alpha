#lang racket/base

(require net/base64
         racket/contract)

(provide (contract-out
          [ create-basic-auth-header (-> string? string? string?) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (create-basic-auth-header username password)
  (string-append
   "Authorization: Basic "
   (bytes->string/utf-8 (base64-encode
                         (string->bytes/utf-8
                          (string-append username ":" password))
                         ""))))

;; ---------------------------------------------------------------------------------------------
;; Tests
;; ---------------------------------------------------------------------------------------------

(module+ test
  (require rackunit)

  ;; ------------------------------------------------------------------------------------------
  ;; create-basic-auth-header
  ;; ------------------------------------------------------------------------------------------

  (let ([ username "Aladdin"    ]
        [ password "OpenSesame" ])
    (check-equal? (create-basic-auth-header username password)
                  "Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l"))

  )
