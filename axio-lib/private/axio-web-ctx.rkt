#lang racket

(require "./axio-init-structs.rkt")

(require db
         web-server/http)

(provide (contract-out
          [ build-webctx
            (-> request? hash? hash? connection? axio-context? webctx?) ])
         (struct-out webctx))

(struct webctx (request
                attributes
                session
                connection
                axioctx)
        #:transparent)

(define (build-webctx request
                      attributes
                      session
                      connection
                      axioctx)
  (webctx request
          attributes
          session
          connection
          axioctx))
