#lang racket

(require (for-syntax racket/syntax
                     racket/function
                     racket/string
                     syntax/parse)
         "./axio-router.rkt"
         threading
         net/uri-codec)

(provide generate-router
         generate-url-for
         routes)

(define (axio-format-url path hsh query-params)

  (define (substitute str)
    (if (string-prefix? str "~")
        (~a (hash-ref hsh (substring str 1)))
        str))

  (define (add-query-params path)
    (if (empty? query-params)
        path
        (~a path "?" (alist->form-urlencoded query-params))))

  (~> (string-split path "/" #:trim? #f)
      (map substitute _)
      (string-join _ "/")
      add-query-params))

(define-syntax (generate-router stx)
  (syntax-parse stx
    [(_ route-fun:id do-route:expr not-found-func:expr (path:string func:expr pred?:expr) ...)
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
    [(_ url-for-fun:id (path:string (~optional route-name:id)) ...)
     #'(begin
         (define hsh (make-immutable-hash '((~? (route-name . path)) ...)))

         (define/contract (url-for-fun a-route-name [ arg (hash) ] #:query [ query-params '() ])
           (->* (symbol?)
                (hash?
                 #:query (listof (cons/c symbol? (or/c #f string?))))
                string?)
           (axio-format-url (hash-ref hsh a-route-name) arg query-params))) ]))

(define-syntax (routes stx)
  (syntax-parse stx
    [(_ (~optional (~seq #:url-fun url-for-fun:id)
                   #:defaults ([url-for-fun (format-id #'r "axio-url-for")]))
        (path:string
         func:expr
         (~optional (~seq #:name route-name:id))
         (~optional (~seq #:when pred?:expr)
                    #:defaults ([pred? #'(const #t)]))
         #;(~optional (~seq #:methods method-lst:expr)
                      #:defaults ([method-lst #''()]))) ...
        not-found-func:expr)
     #:with route-fun (format-id #'r "axio-route")
     #'(begin
         (provide route-fun url-for-fun)
         (generate-router route-fun axio-do-route not-found-func (path func pred?) ...)
         (generate-url-for url-for-fun (path (~? route-name)) ...))]))

