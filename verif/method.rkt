#lang rosette

(require serval/lib/core
         "./lib/llvm-extend.rkt"
         "./const.rkt"
         "./util.rkt"
         "./misc.rkt"
         "./predicate.rkt")

(provide (all-defined-out))

(define (pre-check_sufficient_avail_blocks mach flash mrs0 abst)
  #t)

(define (post-check_sufficient_avail_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (list (tagcond/desp 'method null (bvule erasable (bv64 (- BLOCKS_DATA 36))))))

(define (pre-check_sufficient_ready_blocks mach flash mrs0 abst)
  #t)

(define (post-check_sufficient_ready_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (list (tagcond/desp 'method null (sufficient-ready-blocks usable used))))