#lang racket

(require "./axio-init-structs.rkt")

(require db
         web-server/http)

(provide (contract-out
          [ build-webctx
            (-> request? hash? hash? connection? axio-context? procedure? webctx?) ])
         (struct-out webctx))

(struct webctx (request
                attributes
                session
                connection
                axioctx
                url-for)
        #:transparent)

(define (build-webctx request
                      attributes
                      session
                      connection
                      axioctx
                      url-for)
  (webctx request
          attributes
          session
          connection
          axioctx
          url-for))
