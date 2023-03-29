#lang racket/base

(require file/sha1
         racket/contract
         racket/random)

(provide (contract-out
          [ hash-password (-> string? string? string?) ]
          [ hash-string   (-> string? string?)         ]
          [ random-string (-> exact-integer? string?)  ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (hash-password password salt)
  (hash-string (string-append password salt)))

(define (hash-string str)
  (let* ([ source-bytes (string->bytes/utf-8 str)      ]
         [ hash-bytes   (sha256-bytes source-bytes)    ]
         [ dest-str     (bytes->hex-string hash-bytes) ])
    dest-str))

(define (random-string n)
  (let* ([ half-n       (ceiling (/ n 2))                ]
         [ random-bytes (crypto-random-bytes half-n)     ]
         [ str          (bytes->hex-string random-bytes) ])
    (if (even? n)
        str
        (substring str 0 n))))

;; ---------------------------------------------------------------------------------------------
;; Tests
;; ---------------------------------------------------------------------------------------------

(module+ test
  (require rackunit)

  (check-equal? (hash-string "hello, world!")
                "68e656b251e67e8358bef8483ab0d51c6619f3e7a1a9f0e75838d41ff368f728")

  ;; Verify we handle even/odd string lengths properly since we
  ;; produce the string by doubling the bytes via bytes->hex-string
  (for ([n '(0 1 2 7 100 101)])
    (check-equal? (string-length (random-string n)) n))

  )
