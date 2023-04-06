#lang racket/base

(require "./axio-config.rkt")

(require db
         gregor
         racket/contract
         racket/string)

(provide (contract-out
          [ db-connect
            (-> axio-db-config? any) ]
          [ db-maybe-date
            (-> vector? exact-nonnegative-integer? (or/c date? #f)) ]
          [ db-maybe-string
            (-> vector? exact-nonnegative-integer? (or/c string? #f)) ]
          [ db-maybe-timestamptz
            (-> vector? exact-nonnegative-integer? (or/c moment-provider? #f)) ]
          [ db-safe-boolean
            (-> vector? exact-nonnegative-integer? (or/c boolean? #f)) ]
          [ db-safe-str
            (-> vector? exact-nonnegative-integer? (or/c string? #f)) ]
          [ db-write-date
            (-> date? (or/c sql-date? sql-null?)) ]
          [ db-write-string
            (-> (or/c string? #f) (or/c string? sql-null?)) ]
          [ db-write-timestamptz
            (-> (or/c moment-provider? #f) (or/c sql-timestamp? sql-null?)) ]
          [ sql-timestamp->moment
            (-> (or/c sql-timestamp? sql-null?) (or/c moment-provider? #f)) ]
          [ where-string-values
            (-> (listof (cons/c string? any/c)) (values string? list?)) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (db-connect db-config)
  (postgresql-connect #:user     (axio-db-config-username db-config)
                      #:password (axio-db-config-password db-config)
                      #:server   (axio-db-config-server   db-config)
                      #:database (axio-db-config-database db-config)))

(define (db-maybe-date row idx)
  (let ([obj (vector-ref row idx)])
    (if (sql-null? obj)
        #f
        (sql-date->date obj))))

(define (db-maybe-string row idx)
  (let ([obj (vector-ref row idx)])
    (if (sql-null? obj)
        #f
        (if (string? obj)
            obj
            (error "db-maybe-string: not a string")))))

(define (db-maybe-timestamptz row idx)
  (let ([obj (vector-ref row idx)])
    (if (sql-null? obj)
        #f
        (sql-timestamp->moment obj))))

(define (db-safe row idx default)
  (let ([obj (vector-ref row idx)])
    (if (sql-null? obj)
        default
        obj)))

(define (db-safe-boolean row idx) (db-safe row idx #f))
(define (db-safe-str     row idx) (db-safe row idx ""))

(define (db-write-date obj)
  (if obj
      (date->sql-date obj)
      sql-null))

(define (db-write-string s) (if s s sql-null))

(define (db-write-timestamptz obj)
  (if obj
      (moment->sql-timestamp obj)
      sql-null))

(define (sql-timestamp->moment sql-time)
  (if (sql-null? sql-time)
      #f
      (let ([ m (moment
                 (sql-timestamp-year       sql-time)
                 (sql-timestamp-month      sql-time)
                 (sql-timestamp-day        sql-time)
                 (sql-timestamp-hour       sql-time)
                 (sql-timestamp-minute     sql-time)
                 (sql-timestamp-second     sql-time)
                 (sql-timestamp-nanosecond sql-time)
                 #:tz (sql-timestamp-tz sql-time)) ])
        (adjust-timezone m (current-timezone)))))

;; (where-string-values lst) -> (values string? list?)
;; lst : (listof (cons/c string? any/c))
;;
;; Given a list of pairs (column_name . value), return two values: a string & a list of values.
;; For example: (where-string-values '(("foo" . 7) ("bar" . "baz"))) ->
;; (values "1=1 and foo=$1 and bar=$2" '(7 "baz"))
(define (where-string-values lst)
  ;; ------------------------------------------------------------------------------------------
  ;; Helpers
  ;; ------------------------------------------------------------------------------------------
  (define (add-string-clause str column value i)
    (if (is-wildcard-value? value)
        ; like
        (format "~a and ~a like $~a" str column i)
        ; =
        (format "~a and ~a=$~a" str column i)))

  (define (add-value-clause value vals)
    (if (is-wildcard-value? value)
        (cons (string-replace value #px"\\*$" "%") vals)
        (cons value vals)))

  (define (is-wildcard-value? value)
    (and (string? value)
         (string-suffix? value "*")))
  ;; ------------------------------------------------------------------------------------------
  (let loop ([lst lst] [str "1=1"] [vals '()] [i 1])
    (if (null? lst)
        (values str (reverse vals))
        (let* ([ pair   (car lst)  ]
               [ column (car pair) ]
               [ value  (cdr pair) ])
          (loop (cdr lst)
                (add-string-clause str column value i)
                (add-value-clause value vals)
                (+ i 1))))))

;; --------------------------------------------------------------------------------------------
;; Private Implementation
;; --------------------------------------------------------------------------------------------

;; (date->sql-date obj) -> sql-date
;; obj : date-provider?
(define (date->sql-date obj)
  (sql-date
   (->year obj)
   (->month obj)
   (->day obj)))

;; (moment->sql-timestamp mom) -> sql-timestamp
;; mom : moment-provider?
(define (moment->sql-timestamp mom)
  (sql-timestamp
   (->year        mom)
   (->month       mom)
   (->day         mom)
   (->hours       mom)
   (->minutes     mom)
   (->seconds     mom)
   (->nanoseconds mom)
   (->utc-offset  mom)))

;; (sql-date->date sql-date) -> date
;; sql-date : sql-date?
(define (sql-date->date sql-date)
  (date
   (sql-date-year  sql-date)
   (sql-date-month sql-date)
   (sql-date-day   sql-date)))

;; ---------------------------------------------------------------------------------------------
;; Tests
;; ---------------------------------------------------------------------------------------------

(module+ test
  (require rackunit)

  ;; ------------------------------------------------------------------------------------------
  ;; where-string-values
  ;; ------------------------------------------------------------------------------------------

  (let-values ([ (where-str where-values)
                 (where-string-values '(("foo" . 7) ("bar" . "baz"))) ])
    (check-equal? where-str "1=1 and foo=$1 and bar=$2")
    (check-equal? where-values '(7 "baz")))

  ; String with wildcard *
  (let-values ([ (where-str where-values)
                 (where-string-values '(("foo" . "val*") ("bar" . "baz"))) ])
    (check-equal? where-str "1=1 and foo like $1 and bar=$2")
    (check-equal? where-values '("val%" "baz")))


  )
