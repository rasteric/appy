#lang racket
;; Links - link management, i.e., url-like structures to address objects in the system

(provide link% link-mixin make-link new-link-for associate resolve disassociate stale? clear-links link->list list->link link-addressable<%>)

(define current-links (make-parameter (make-hash)))

(define/contract link%
  (class/c
   [init-field (linkpath (listof any/c))]
   [equal-to? (->m any/c (-> any/c any/c any) any)]
   [equal-hash-code-of (->m any/c any)]
   [equal-secondary-hash-code-of (->m any/c any)])
   
  (class* object% (equal<%>)
    (init-field linkpath)

    (define/public (equal-to? other recur)
      (recur linkpath (get-field linkpath other)))

     (define/public (equal-hash-code-of hash-code)
      (hash-code linkpath))

    (define/public (equal-secondary-hash-code-of hash-code)
      (hash-code linkpath))
    
    (super-new)))

(define (make-link pathlist)
  (make-object link% pathlist))

(define (new-link-for obj pathlist)
  (define link (make-object link% pathlist))
  (associate link obj)
  link)

(define (clear-links)
  (current-links (make-hash)))

(define/contract (link->list link)
  (-> (is-a?/c link%) any)
  (get-field linkpath link))

(define/contract (list->link li)
  (-> (non-empty-listof (or/c symbol? (listof symbol?))) any)
  (new link%
       [linkpath li]))

(define link-addressable<%> (interface () get-link))

(define link-mixin
  (mixin () (link-addressable<%>)
    (init-field link)

    (define/public (get-link)
      link)

    (super-new)
    (associate link this)))

(define/contract (associate link obj)
  (-> (is-a?/c link%) any/c any)
  (hash-set! (current-links) link obj))

(define/contract (resolve link [on-failure #f])
  (->* ((is-a?/c link%)) (any/c) any)
  (hash-ref (current-links) link on-failure))

(define/contract (disassociate link)
  (-> (is-a?/c link%) any)
  (hash-remove! (current-links) link))

(define/contract (stale? link)
  (-> (is-a?/c link%) any)
  (not (hash-has-key? (current-links) link)))


(module+ test
  (require rackunit)

  (define a (make-link '(my first path 1)))
  (define b (make-link '(my second path 2)))
  (define c (make-link '(my third path 3)))
  (define d (make-link '(my fourth path 4)))
  (define e (new-link-for "my test object" '(this is my last link 5)))
  (define f (make-link '(a test (path))))
  (define g (make-link '(a test (path))))
  
  (check-not-exn (lambda () (associate a 'test)))
  (check-not-exn (lambda () (associate b 'test)))
  (check-not-exn (lambda () (associate c a)))

  (check-equal? (resolve a #f) 'test)
  (check-equal? (resolve b #f) 'test)
  (check-equal? (resolve c) a)

  (check-false (stale? a))
  (check-false (stale? b))
  (check-false (stale? c))
  (check-true (stale? d))
  (check-not-exn (lambda () (disassociate a)))
  (check-not-exn (lambda () (disassociate d)))
  (check-true (stale? d))
  (check-true (stale? a))
  (check-equal? (resolve e) "my test object")
  (collect-garbage)
  (check-equal? (resolve e) "my test object")
  (check-not-exn (lambda () (clear-links)))
  (check-equal? (resolve a) #f)
  (check-equal? (resolve b) #f)
  (check-true (stale? c))
  (check-true (stale? d))
  (check-true (stale? e))
  (check-equal? f g)
  )