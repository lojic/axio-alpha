#lang racket

(require (for-syntax racket/syntax racket/function racket/string))
(require (for-syntax syntax/parse))
(require "./axio-router.rkt")
(require threading)

(provide generate-router
         generate-url-for
         routes)

(define (axio-format-url path hsh)
  (define (substitute str)
    (if (string-prefix? str "~")
        (~a (hash-ref hsh (string->symbol (substring str 1))))
        str))
  
  (~> (string-split path "/" #:trim? #f)
      (map substitute _)
      (string-join _ "/")))

(define-syntax (generate-router stx)
  (syntax-parse stx
    [(_ route-fun do-route not-found-func (path:string func pred?) ...)
     (define paths (map syntax-e (syntax->list #'(path ...))))
     (define splits (for/list ([ path paths ])
                      (string-split path "/")))
     (with-syntax ([ (route-nodes ...) splits ])
       #'(define (route-fun ctx)
           (let-values ([ (web-request method path-nodes) (axio-parse-ctx-path ctx) ])
             (cond
               [ (axio-match-path-to-route web-request path-nodes (quote route-nodes) pred?)
                 => (λ (path-attrs) (do-route func ctx path-attrs)) ] ...
               [ else (not-found-func ctx) ]))))]))
  
(define-syntax (generate-url-for stx)
  (syntax-parse stx
    [(_ url-for-fun (path route-name) ...)
     #'(begin
         (define hsh (make-immutable-hash '((route-name . path) ...)))
         
         (define (url-for-fun a-route-name [ arg (hash) ])
           (axio-format-url (hash-ref hsh a-route-name) arg))) ]))

(define-syntax (routes stx)
  (syntax-parse stx
    [(r (~optional (~seq #:url-fun url-for-fun:id)
                   #:defaults ([url-for-fun (format-id #'r "axio-url-for")]))
        (path func
              (~optional (~seq #:name route-name:id)
                         #:defaults ([route-name #'#f]))
              (~optional (~seq #:when pred?:id)
                         #:defaults ([pred? #'(const #t)]))
              #;(~optional (~seq #:methods method-lst:expr)
                           #:defaults ([method-lst #''()]))) ...
        not-found-func)
     #:with route-fun (format-id #'r "axio-route")
     #'(begin
         (provide route-fun url-for-fun)
         (generate-router route-fun axio-do-route not-found-func (path func pred?) ...)
         (generate-url-for url-for-fun (path route-name) ...))]))

