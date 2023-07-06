#lang racket/base

(require racket/contract)

(provide (contract-out
          [ serialize
            (-> (or/c boolean? bytes? char? hash? list? number? string? symbol? vector?)
                string?) ]
          [ deserialize
            (-> any/c any) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (serialize obj)
  (let ([ostr (open-output-string)])
    (write obj ostr)
    (get-output-string ostr)))

(define (deserialize obj)
  (cond [ (string? obj)
          (read (open-input-string obj)) ]
        [ else #f ]))

;; --------------------------------------------------------------------------------------------
;; Tests
;; --------------------------------------------------------------------------------------------

(module+ test
  (require rackunit)

  (let ([obj '("foo" "bar" "baz")]
        [str "(\"foo\" \"bar\" \"baz\")"])
    (check-equal? (serialize obj) str)
    (check-equal? (deserialize (serialize obj)) obj))

  (let* ([obj #hash(("foo" . 7) ("bar" . "baz"))]
         [str (serialize obj)]
         [obj2 (deserialize str)])
    (for ([key (hash-keys obj)])
      (check-equal? (hash-ref obj key) (hash-ref obj2 key))))

  )
