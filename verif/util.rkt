#lang rosette

(require racket/struct
         serval/lib/core
         "./lib/llvm-extend.rkt"
         "./lib/flash.rkt"
         "./const.rkt"
         "misc.rkt")

(provide (all-defined-out))

(struct abstract (
  ; Spec state variables
  volatile stable wcnt
  ; Aux state variables
  ptr-buf map-ptr-buf ipa-delta pba-used
  map-pba-unstable map-ipa-unstable map-ptr-unstable
  pba-commit ipa-commit
  map-pba-stable map-ipa-stable map-ptr-stable
  n-used-blks isa-active ipa-active
  lsa-gc enable-gc n-gc-copied gcprog) #:transparent #:mutable)

(define (make-abstract)
  (define-symbolic* volatile (~> i32 i64 i32))
  (define-symbolic* stable (~> i32 i64 i32))
  (define-symbolic* wcnt i32)
  (define-symbolic* ptr-buf i32)
  (define-symbolic* map-ptr-buf (~> i32 i64))
  (define-symbolic* ipa-delta i32)
  (define-symbolic* pba-used i32)
  (define-symbolic* map-pba-unstable (~> i32 i32))
  (define-symbolic* map-ipa-unstable (~> i32 i32))
  (define-symbolic* map-ptr-unstable (~> i32 i64))
  (define-symbolic* pba-commit i32)
  (define-symbolic* ipa-commit i32)
  (define-symbolic* map-pba-stable (~> i32 i32))
  (define-symbolic* map-ipa-stable (~> i32 i32))
  (define-symbolic* map-ptr-stable (~> i32 i64))
  (define-symbolic* n-used-blks i64)
  (define-symbolic* isa-active i32)
  (define-symbolic* ipa-active i32)
  (define-symbolic* lsa-gc i32)
  (define-symbolic* enable-gc i32)
  (define-symbolic* n-gc-copied i32)
  (define-symbolic* gcprog i32)
  (abstract
    volatile stable wcnt
    ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
    pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
    n-used-blks isa-active ipa-active
    lsa-gc enable-gc n-gc-copied gcprog))

(define (retrieve-abstract abst)
  (apply values (struct->list abst)))

(define (retrieve-machine mach)
  (define mregions (machine-mregions mach))
  (define block-l2p (find-block-by-name mregions 'l2p))
  (define block-p2l (find-block-by-name mregions 'p2l))
  (define block-buf_merge (find-block-by-name mregions 'buf_merge))
  (define block-buf_gc (find-block-by-name mregions 'buf_gc))
  (define block-lsas_merge (find-block-by-name mregions 'lsas_merge))
  (define block-isa_active (find-block-by-name mregions 'isa_active))
  (define block-ipa_active (find-block-by-name mregions 'ipa_active))
  (define block-pba_active (find-block-by-name mregions 'pba_active))
  (define block-isa_gc (find-block-by-name mregions 'isa_gc))
  (define block-ipa_gc (find-block-by-name mregions 'ipa_gc))
  (define block-pba_gc (find-block-by-name mregions 'pba_gc))
  (define block-lsa_gc (find-block-by-name mregions 'lsa_gc))
  (define block-gcprog (find-block-by-name mregions 'gcprog))
  (define block-enable_gc (find-block-by-name mregions 'enable_gc))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define buf_merge (lambda (x) (mblock-iload block-buf_merge (list x))))
  (define buf_gc (lambda (x) (mblock-iload block-buf_gc (list x))))
  (define lsas_merge (lambda (x) (mblock-iload block-lsas_merge (list x))))
  (define isa_active (mblock-iload block-isa_active null))
  (define ipa_active (mblock-iload block-ipa_active null))
  (define pba_active (mblock-iload block-pba_active null))
  (define isa_gc (mblock-iload block-isa_gc null))
  (define ipa_gc (mblock-iload block-ipa_gc null))
  (define pba_gc (mblock-iload block-pba_gc null))
  (define lsa_gc (mblock-iload block-lsa_gc null))
  (define gcprog (mblock-iload block-gcprog null))
  (define enable_gc (mblock-iload block-enable_gc null))
  ; chkpt
  (define block-delta_buf (find-block-by-name mregions 'delta_buf))
  (define block-ptr_delta_buf (find-block-by-name mregions 'ptr_delta_buf))
  (define block-pba_delta (find-block-by-name mregions 'pba_delta))
  (define block-ipa_delta (find-block-by-name mregions 'ipa_delta))
  (define block-ptr_full (find-block-by-name mregions 'ptr_full))
  (define block-wcnt (find-block-by-name mregions 'wcnt))
  (define delta_buf (lambda (x) (mblock-iload block-delta_buf (list x))))
  (define ptr_delta_buf (mblock-iload block-ptr_delta_buf null))
  (define pba_delta (mblock-iload block-pba_delta null))
  (define ipa_delta (mblock-iload block-ipa_delta null))
  (define ptr_full (mblock-iload block-ptr_full null))
  (define wcnt (mblock-iload block-wcnt null))
  ; blk list
  (define block-blk_list (find-block-by-name mregions 'blk_list))
  (define block-usable (find-block-by-name mregions 'usable))
  (define block-erasable (find-block-by-name mregions 'erasable))
  (define block-invalid (find-block-by-name mregions 'invalid))
  (define block-used (find-block-by-name mregions 'used))
  (define block-active (find-block-by-name mregions 'active))
  (define blk_list (lambda (x) (mblock-iload block-blk_list (list x))))
  (define usable (mblock-iload block-usable null))
  (define erasable (mblock-iload block-erasable null))
  (define invalid (mblock-iload block-invalid null))
  (define used (mblock-iload block-used null))
  (define active (mblock-iload block-active null))
  (values
    l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
    isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
    delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
    blk_list usable erasable invalid used active))

(define (retrieve-mregions mregions)
  (define block-l2p (find-block-by-name mregions 'l2p))
  (define block-p2l (find-block-by-name mregions 'p2l))
  (define block-buf_merge (find-block-by-name mregions 'buf_merge))
  (define block-buf_gc (find-block-by-name mregions 'buf_gc))
  (define block-lsas_merge (find-block-by-name mregions 'lsas_merge))
  (define block-isa_active (find-block-by-name mregions 'isa_active))
  (define block-ipa_active (find-block-by-name mregions 'ipa_active))
  (define block-pba_active (find-block-by-name mregions 'pba_active))
  (define block-ipa_gc (find-block-by-name mregions 'ipa_gc))
  (define block-pba_gc (find-block-by-name mregions 'pba_gc))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define buf_merge (lambda (x) (mblock-iload block-buf_merge (list x))))
  (define buf_gc (lambda (x) (mblock-iload block-buf_gc (list x))))
  (define lsas_merge (lambda (x) (mblock-iload block-lsas_merge (list x))))
  (define isa_active (mblock-iload block-isa_active null))
  (define ipa_active (mblock-iload block-ipa_active null))
  (define pba_active (mblock-iload block-pba_active null))
  (define ipa_gc (mblock-iload block-ipa_gc null))
  (define pba_gc (mblock-iload block-pba_gc null))
  ; chkpt
  (define block-delta_buf (find-block-by-name mregions 'delta_buf))
  (define block-ptr_delta_buf (find-block-by-name mregions 'ptr_delta_buf))
  (define block-pba_delta (find-block-by-name mregions 'pba_delta))
  (define block-ipa_delta (find-block-by-name mregions 'ipa_delta))
  (define block-ptr_full (find-block-by-name mregions 'ptr_full))
  (define block-wcnt (find-block-by-name mregions 'wcnt))
  (define delta_buf (lambda (x) (mblock-iload block-delta_buf (list x))))
  (define ptr_delta_buf (mblock-iload block-ptr_delta_buf null))
  (define pba_delta (mblock-iload block-pba_delta null))
  (define ipa_delta (mblock-iload block-ipa_delta null))
  (define ptr_full (mblock-iload block-ptr_full null))
  (define wcnt (mblock-iload block-wcnt null))
  ; blk list
  (define block-blk_list (find-block-by-name mregions 'blk_list))
  (define block-usable (find-block-by-name mregions 'usable))
  (define block-erasable (find-block-by-name mregions 'erasable))
  (define block-invalid (find-block-by-name mregions 'invalid))
  (define block-used (find-block-by-name mregions 'used))
  (define block-active (find-block-by-name mregions 'active))
  (define blk_list (lambda (x) (mblock-iload block-blk_list (list x))))
  (define usable (mblock-iload block-usable null))
  (define erasable (mblock-iload block-erasable null))
  (define invalid (mblock-iload block-invalid null))
  (define used (mblock-iload block-used null))
  (define active (mblock-iload block-active null))
  (values
    l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active ipa_gc pba_gc
    delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
    blk_list usable erasable invalid used active))

(define (gen-valcond valcond mach)
  (define block-failed (find-block-by-name (machine-mregions mach) 'failed))
  (define failed (mblock-iload block-failed null))
  (=>
    (bveq failed (bv32 0))
    valcond))

(define (required-conjuncts conjs tags)
  (define conjs-sel
    (if (list? tags)
        (filter (lambda (conj) (member (car conj) tags)) conjs)
        conjs))
  ; (printf " ~a" tags)
  ; (printf " (~a conjuncts)" (length conjs-sel))
  (apply && (map cdr conjs-sel)))

(define (host-data-pointer)
  (define ptr (pointer (global->symbol '@host_data) (bvpointer 0)))
  ptr)

(define (dump-func cex name n width pre post)
  (printf "~v\n" name)
  (for-each (lambda (x) (printf "~v " (bitvector->natural (evaluate (pre (bv x width)) cex)))) (range n))
  (printf " -> ")
  (for-each (lambda (x) (printf "~v " (bitvector->natural (evaluate (post (bv x width)) cex)))) (range n))
  (printf "\n"))

(define (cex-handler cex mrs flash abst mrs0 flash0 abst0)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active ipa_gc pba_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-mregions mrs))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define-values
    (volatile stable wcnt-abs
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog-abs)
    (retrieve-abstract abst))
  (define-values
    (l2p0 p2l0 buf_merge0 buf_gc0 lsas_merge0 isa_active0 ipa_active0 pba_active0 ipa_gc0 pba_gc0
     delta_buf0 ptr_delta_buf0 pba_delta0 ipa_delta0 ptr_full0 wcnt0
     blk_list0 free0 erasable0 invalid0 used0 active0)
    (retrieve-mregions mrs0))
  (define-values
    (erased0 synced0 data0)
    (retrieve-flash flash0))
  (define-values
    (volatile0 stable0 wcnt-abs0
     ptr-buf0 map-ptr-buf0 ipa-delta0 pba-used0 map-pba-unstable0 map-ipa-unstable0 map-ptr-unstable0
     pba-commit0 ipa-commit0 map-pba-stable0 map-ipa-stable0 map-ptr-stable0
     n-used-blks0 isa-active0 ipa-active0
     lsa-gc0 enable-gc0 n-gc-copied0 gcprog-abs0)
    (retrieve-abstract abst0))

  (define (disk0 l)
    (define addr (psa->pba-ipa-isa64 (l2p0 (zext64 l))))
    (cond
      [(bveq l (lsas_merge0 (bv64 1))) (buf_merge0 (bv64 1))]
      [(bveq l (lsas_merge0 (bv64 0))) (buf_merge0 (bv64 0))]
      [else (apply data0 addr)]))

  (define (disk l)
    (define addr (psa->pba-ipa-isa64 (l2p (zext64 l))))
    (cond
      [(bveq l (lsas_merge (bv64 1))) (buf_merge (bv64 1))]
      [(bveq l (lsas_merge (bv64 0))) (buf_merge (bv64 0))]
      [else (apply data addr)]))

  (dump-func cex 'l2p 7 64 l2p0 l2p)
  (dump-func cex 'p2l 1 64 p2l0 p2l)
  (dump-func cex 'lsas_merge 2 64 lsas_merge0 lsas_merge)
  (dump-func cex 'buf_merge 2 64 buf_merge0 buf_merge)
  (dump-func cex 'buf_gc 2 64 buf_gc0 buf_gc)
  ; (dump-func cex 'volatile 7 64 volatile0 volatile)
  (dump-func cex 'disk 7 32 disk0 disk))
