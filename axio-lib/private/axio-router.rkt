#lang racket

(require "./axio-web-ctx.rkt"
         net/url-structs
         racket/hash
         web-server/http)

(provide axio-do-route
         axio-match-path-to-route
         axio-parse-ctx-path)

(define (axio-do-route func ctx path-attrs)
  (func (struct-copy webctx
                     ctx
                     [ attributes (hash-union (webctx-attributes ctx)
                                              path-attrs) ])))

(define (axio-match-path-to-route web-request path-nodes route-nodes pred?)
  (let loop ([ path-nodes  path-nodes  ]
             [ route-nodes route-nodes ]
             [ attrs       (hash)      ])
    (let ([ path-empty?  (null? path-nodes)  ]
          [ route-empty? (null? route-nodes) ])
      (cond [ (and path-empty? route-empty?)
              ; We've consumed both lists, so paths match, and we have attributes, if any.
              ; If the predicate is #t, return the attrs
              (if (pred? web-request attrs)
                  attrs
                  #f) ]
            [ (or path-empty? route-empty?)
              ; One, but not both, of the lists is empty, no match
              #f ]
            [ else
              (let ([ path-node  (car path-nodes)  ]
                    [ route-node (car route-nodes) ])
                (cond [ (string-prefix? route-node "~")
                        ; route variable substitution
                        (loop (cdr path-nodes) (cdr route-nodes) (hash-set attrs
                                                                           (substring route-node 1)
                                                                           path-node)) ]
                      [ (string=? path-node route-node)
                        ; nodes match
                        (loop (cdr path-nodes) (cdr route-nodes) attrs) ]
                      [ else
                        ; nodes do not match
                        #f ])) ]))))

(define (axio-parse-ctx-path ctx)
  (let* ([ request  (webctx-request ctx)     ]
         [ method   (request-method request) ]
         [ url      (request-uri request)    ]
         [ path     (map (λ (pp) (path/param-path pp)) (url-path url)) ])
    (values request (bytes->string/utf-8 method) path)))

