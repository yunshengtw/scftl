#lang rosette

(require serval/lib/core 
         "./lib/llvm-extend.rkt"
         "./const.rkt"
         "./misc.rkt"
         "./util.rkt")

(provide (all-defined-out))

(define (spec-write abst ndvar la data)
  ; old values (before transition)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))

  ; non-determinism of crash
  (define crash-abst0 (struct-copy abstract abst))

  (define mblock-data (pointer-block data))
  (define dataf (lambda (x) (mblock-iload mblock-data (list x))))
  ; spec transition
  (when
    (&& (bvult la (bv32 N_LAS)) (bvult wcnt (bv32 MAX_WCNT)))
    (set-abstract-volatile!
      abst
      (lambda (lsa offset) (if
        (bveq lsa la)
        (dataf offset)
        (volatile lsa offset))))
    (set-abstract-wcnt! abst (bvadd wcnt (bv32 1))))

  (when
    (&& (bvult la (bv32 N_LAS)) (bvult wcnt (bv32 MAX_WCNT)))
    (if
      (bveq ptr-buf (bv32 N_DELTA_PAIR))
      (begin
        (set-abstract-ptr-buf! abst (bv32 1))
        (set-abstract-map-ptr-buf!
          abst
          (lambda (x) (if (bveq x la) (bv64 0) (bv64 N_DELTA_PAIR))))
        (if
          (bveq ipa-delta (bv32 PAGES_PER_BLOCK))
          (begin
            (set-abstract-ipa-delta! abst (bv32 1))
            (set-abstract-pba-used! abst (bvadd pba-used (bv32 1)))
            (set-abstract-map-pba-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-pba-unstable x)
                (bvadd pba-used (bv32 1)))))
            (set-abstract-map-ipa-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ipa-unstable x)
                (bv32 0))))
            (set-abstract-map-ptr-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ptr-unstable x)
                (map-ptr-buf x)))))
          (begin
            (set-abstract-ipa-delta! abst (bvadd ipa-delta (bv32 1)))
            (set-abstract-map-pba-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-pba-unstable x)
                pba-used)))
            (set-abstract-map-ipa-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ipa-unstable x)
                ipa-delta)))
            (set-abstract-map-ptr-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ptr-unstable x)
                (map-ptr-buf x)))))))
      (begin
        (set-abstract-ptr-buf! abst (bvadd ptr-buf (bv32 1)))
        (set-abstract-map-ptr-buf!
          abst
          (lambda (x) (if
            (bveq x la)
            (zext64 ptr-buf)
            (map-ptr-buf x))))))
    (if
      (bveq isa-active (bv32 SECTORS_PER_PAGE))
      (begin
        (set-abstract-isa-active! abst (bv32 1))
        (if
          (bveq ipa-active (bv32 (- PAGES_PER_BLOCK 1)))
          (begin
            (set-abstract-ipa-active! abst (bv32 0))
            (set-abstract-n-used-blks! abst (bvadd n-used-blks (bv64 1))))
          (set-abstract-ipa-active! abst (bvadd ipa-active (bv32 1)))))
      (set-abstract-isa-active! abst (bvadd isa-active (bv32 1))))
    (when
      (bveq la lsa-gc)
      (set-abstract-lsa-gc! abst (bv32 N_LAS))))

  ; stable (pba-commit, ipa-commit, map-*-stable): all remains

  ; crash spec: all remains
  (list crash-abst0))

(define (spec-flush abst ndvar)
  ; old values (before transition)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))

  ; non-determinism of crash
  (define crash-abst0 (struct-copy abstract abst))
  (define crash-abst1 (struct-copy abstract abst))
  (define crash-abst2 (struct-copy abstract abst))
  (define crash-abst3 (struct-copy abstract abst))
  (define crash-abst4 (struct-copy abstract abst))

  ; spec transition
  (set-abstract-stable! abst volatile)
  (set-abstract-wcnt! abst (bv32 0))

  ; unstable (ptr-buf, map-ptr-buf, pba-used, ipa-delta, map-*-unstable)
  (set-abstract-ptr-buf! abst (bv32 0))
  (set-abstract-map-ptr-buf!
    abst
    (lambda (x) (bv64 N_DELTA_PAIR)))
  (if
    (bveq ipa-delta (bv32 PAGES_PER_BLOCK))
    (begin
      (set-abstract-ipa-delta! abst (bv32 1))
      (set-abstract-pba-used! abst (bvadd pba-used (bv32 1)))
      (set-abstract-map-pba-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-pba-unstable x)
          (bvadd pba-used (bv32 1)))))
      (set-abstract-map-ipa-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-ipa-unstable x)
          (bv32 0))))
      (set-abstract-map-ptr-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-ptr-unstable x)
          (map-ptr-buf x)))))
    (begin
      (set-abstract-ipa-delta! abst (bvadd ipa-delta (bv32 1)))
      (set-abstract-map-pba-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-pba-unstable x)
          pba-used)))
      (set-abstract-map-ipa-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-ipa-unstable x)
          ipa-delta)))
      (set-abstract-map-ptr-unstable!
        abst
        (lambda (x) (if
          (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
          (map-ptr-unstable x)
          (map-ptr-buf x))))))
  (when
    (bvuge (abstract-pba-used abst) (bv32 THRESHOLD_DELTA_WB))
    (set-abstract-ipa-delta! abst (bv32 1))
    (set-abstract-pba-used! abst (bv32 0))
    (set-abstract-map-pba-unstable!
      abst
      (lambda (x) (bv32 BLOCKS_DELTA)))
    (set-abstract-map-ipa-unstable!
      abst
      (lambda (x) (bv32 PAGES_PER_BLOCK)))
    (set-abstract-map-ptr-unstable!
      abst
      (lambda (x) (bv64 N_DELTA_PAIR))))

  ; stable (pba-commit, ipa-commit, map-*-stable)
  (set-abstract-pba-commit! abst (abstract-pba-used abst))
  (set-abstract-ipa-commit! abst (abstract-ipa-delta abst))
  (set-abstract-map-pba-stable!
    abst
    (abstract-map-pba-unstable abst))
  (set-abstract-map-ipa-stable!
    abst
    (abstract-map-ipa-unstable abst))
  (set-abstract-map-ptr-stable!
    abst
    (abstract-map-ptr-unstable abst))

  (unless
    (bveq isa-active (bv32 0))
    (if
      (bveq ipa-active (bv32 (- PAGES_PER_BLOCK 1)))
      (begin
        (set-abstract-ipa-active! abst (bv32 0))
        (set-abstract-n-used-blks! abst (bvadd n-used-blks (bv64 1))))
      (set-abstract-ipa-active! abst (bvadd ipa-active (bv32 1)))))
  (set-abstract-isa-active! abst (bv32 0))
  (set-abstract-gcprog! abst (bv32 0))

  ; first crash spec: all remains

  ; second crash spec: stable changed; does not trigger full chkpt;
  ; move to next delta block
  (set-abstract-stable! crash-abst1 volatile)
  (set-abstract-pba-commit! crash-abst1 (bvadd pba-used (bv32 1)))
  (set-abstract-ipa-commit! crash-abst1 (bv32 1))
  (set-abstract-map-pba-stable!
    crash-abst1
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-pba-unstable x)
      (bvadd pba-used (bv32 1)))))
  (set-abstract-map-ipa-stable!
    crash-abst1
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-ipa-unstable x)
      (bv32 0))))
  (set-abstract-map-ptr-stable!
    crash-abst1
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-ptr-unstable x)
      (map-ptr-buf x))))

  ; third crash spec: stable changed; does not trigger full chkpt;
  ; move to next delta page
  (set-abstract-stable! crash-abst2 volatile)
  (set-abstract-pba-commit! crash-abst2 pba-used)
  (set-abstract-ipa-commit! crash-abst2 (bvadd ipa-delta (bv32 1)))
  (set-abstract-map-pba-stable!
    crash-abst2
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-pba-unstable x)
      pba-used)))
  (set-abstract-map-ipa-stable!
    crash-abst2
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-ipa-unstable x)
      ipa-delta)))
  (set-abstract-map-ptr-stable!
    crash-abst2
    (lambda (x) (if
      (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
      (map-ptr-unstable x)
      (map-ptr-buf x))))

  ; fourth crash spec: stable changed; trigger full chkpt;
  ; first delta chkpt erased but not written
  (set-abstract-stable! crash-abst3 volatile)
  (set-abstract-ipa-commit! crash-abst3 (bv32 0))
  (set-abstract-pba-commit! crash-abst3 (bv32 0))
  (set-abstract-map-pba-stable!
    crash-abst3
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable!
    crash-abst3
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable!
    crash-abst3
    (lambda (x) (bv64 N_DELTA_PAIR)))

  ; fifth crash spec: stable changed; trigger full chkpt;
  ; first delta chkpt written
  (set-abstract-stable! crash-abst4 volatile)
  (set-abstract-ipa-commit! crash-abst4 (bv32 1))
  (set-abstract-pba-commit! crash-abst4 (bv32 0))
  (set-abstract-map-pba-stable!
    crash-abst4
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable!
    crash-abst4
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable!
    crash-abst4
    (lambda (x) (bv64 N_DELTA_PAIR)))

  (list crash-abst0 crash-abst1 crash-abst2 crash-abst3 crash-abst4))

(define (spec-recovery abst ndvar)
  ; old values (before transition)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))

  (define any-n-used-blks (list-ref ndvar 0))

  ; non-determinism of crash
  (define crash-abst0 (struct-copy abstract abst))
  (define crash-abst1 (struct-copy abstract abst))
  (define crash-abst2 (struct-copy abstract abst))

  ; spec transition
  (set-abstract-volatile! abst stable)
  (set-abstract-wcnt! abst (bv32 0))

  ; unstable (ptr-buf, map-ptr-buf, pba-used, ipa-delta, map-*-unstable)
  (set-abstract-ptr-buf! abst (bv32 0))
  (set-abstract-map-ptr-buf!
    abst
    (lambda (x) (bv64 N_DELTA_PAIR)))
  (set-abstract-ipa-delta! abst (bv32 1))
  (set-abstract-pba-used! abst (bv32 0))
  (set-abstract-map-pba-unstable!
    abst
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-unstable!
    abst
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-unstable!
    abst
    (lambda (x) (bv64 N_DELTA_PAIR)))

  ; stable (pba-commit, ipa-commit, map-*-stable)
  (set-abstract-ipa-commit! abst (bv32 1))
  (set-abstract-pba-commit! abst (bv32 0))
  (set-abstract-map-pba-stable!
    abst
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable!
    abst
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable!
    abst
    (lambda (x) (bv64 N_DELTA_PAIR)))

  (set-abstract-isa-active! abst (bv32 0))
  (set-abstract-ipa-active! abst (bv32 0))
  (set-abstract-n-used-blks! abst any-n-used-blks)
  (set-abstract-lsa-gc! abst (bv32 N_LAS))
  (set-abstract-enable-gc! abst (bv32 0))
  (set-abstract-n-gc-copied! abst (bv32 0))
  (set-abstract-gcprog! abst (bv32 0))

  ; first crash spec: stable remains; delta chkpt not erased

  ; second crash spec: stable remains; delta chkpt erased; first delta chkpt page not written
  (set-abstract-ipa-commit! crash-abst1 (bv32 0))
  (set-abstract-pba-commit! crash-abst1 (bv32 0))
  (set-abstract-map-pba-stable!
    crash-abst1
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable!
    crash-abst1
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable!
    crash-abst1
    (lambda (x) (bv64 N_DELTA_PAIR)))

  ; third crash spec: stable remains; delta chkpt erased; first delta chkpt page written
  (set-abstract-ipa-commit! crash-abst2 (bv32 1))
  (set-abstract-pba-commit! crash-abst2 (bv32 0))
  (set-abstract-map-pba-stable!
    crash-abst2
    (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable!
    crash-abst2
    (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable!
    crash-abst2
    (lambda (x) (bv64 N_DELTA_PAIR)))

  (list crash-abst0 crash-abst1 crash-abst2))

(define (spec-gc_copy abst ndvar)
  ; old values (before transition)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))

  (define any-lsa-gc (list-ref ndvar 0))
  (define any-gc-prog (list-ref ndvar 1))

  ; non-determinism of crash
  (define crash-abst0 (struct-copy abstract abst))

  ; spec transition: all remains

  ; aux transition
  (when
    (&&
      (bveq enable-gc (bv32 0))
      (bvuge n-used-blks (bv64 THRESHOLD_GC)))
    (set-abstract-enable-gc! abst (bv32 1))
    (set-abstract-n-gc-copied! abst (bv32 0)))

  (when
    (&&
      (bvult gcprog (bv32 MAX_GCPROG))
      (! (bveq enable-gc (bv32 0))))
    (set-abstract-n-gc-copied! abst (bvadd n-gc-copied (bv32 1)))
    (when
      (bveq n-gc-copied (bv32 (- SECTORS_PER_BLOCK 1)))
      (set-abstract-n-gc-copied! abst (bv32 0))
      (set-abstract-enable-gc! abst (bv32 0))
      (set-abstract-n-used-blks! abst (bvsub n-used-blks (bv64 1)))))

  (when
    (&&
      (bvult gcprog (bv32 MAX_GCPROG))
      (! (bveq enable-gc (bv32 0)))
      (bvult lsa-gc (bv32 N_LAS)))
    (if
      (bveq ptr-buf (bv32 N_DELTA_PAIR))
      (begin
        (set-abstract-ptr-buf! abst (bv32 1))
        (set-abstract-map-ptr-buf!
          abst
          (lambda (x) (if (bveq x lsa-gc) (bv64 0) (bv64 N_DELTA_PAIR))))
        (if
          (bveq ipa-delta (bv32 PAGES_PER_BLOCK))
          (begin
            (set-abstract-ipa-delta! abst (bv32 1))
            (set-abstract-pba-used! abst (bvadd pba-used (bv32 1)))
            (set-abstract-map-pba-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-pba-unstable x)
                (bvadd pba-used (bv32 1)))))
            (set-abstract-map-ipa-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ipa-unstable x)
                (bv32 0))))
            (set-abstract-map-ptr-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ptr-unstable x)
                (map-ptr-buf x)))))
          (begin
            (set-abstract-ipa-delta! abst (bvadd ipa-delta (bv32 1)))
            (set-abstract-map-pba-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-pba-unstable x)
                pba-used)))
            (set-abstract-map-ipa-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ipa-unstable x)
                ipa-delta)))
            (set-abstract-map-ptr-unstable!
              abst
              (lambda (x) (if
                (bveq (map-ptr-buf x) (bv64 N_DELTA_PAIR))
                (map-ptr-unstable x)
                (map-ptr-buf x)))))))
      (begin
        (set-abstract-ptr-buf! abst (bvadd ptr-buf (bv32 1)))
        (set-abstract-map-ptr-buf!
          abst
          (lambda (x) (if
            (bveq x lsa-gc)
            (zext64 ptr-buf)
            (map-ptr-buf x))))))
    (if
      (bveq isa-active (bv32 SECTORS_PER_PAGE))
      (begin
        (set-abstract-isa-active! abst (bv32 1))
        (if
          (bveq ipa-active (bv32 (- PAGES_PER_BLOCK 1)))
          (begin
            (set-abstract-ipa-active! abst (bv32 0))
            (set-abstract-n-used-blks! abst (bvadd (abstract-n-used-blks abst) (bv64 1))))
          (set-abstract-ipa-active! abst (bvadd ipa-active (bv32 1)))))
      (set-abstract-isa-active! abst (bvadd isa-active (bv32 1)))))

  (set-abstract-gcprog! abst any-gc-prog)
  (set-abstract-lsa-gc! abst any-lsa-gc)

  ; stable (pba-commit, ipa-commit, map-*-stable): all remains

  ; crash spec: all remains
  (list crash-abst0))

(define (spec-gc_erase abst ndvar)
  ; old values (before transition)
  (define crash-abst0 (struct-copy abstract abst))
  
  (list crash-abst0))

(define (spec-read abst la)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))
  (define data (lambda (x) (volatile la x)))
  data)

(define (spec-format abst)
  (define-values
    (volatile stable wcnt
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog)
    (retrieve-abstract abst))
  (set-abstract-stable! abst (lambda (lsa offset) (bv32 -1)))
  (set-abstract-pba-commit! abst (bv32 0))
  (set-abstract-ipa-commit! abst (bv32 0))
  (set-abstract-map-pba-stable! abst (lambda (x) (bv32 BLOCKS_DELTA)))
  (set-abstract-map-ipa-stable! abst (lambda (x) (bv32 PAGES_PER_BLOCK)))
  (set-abstract-map-ptr-stable! abst (lambda (x) (bv64 N_DELTA_PAIR))))

(define (ndvar-null)
  null)

(define (ndvar-gc_copy)
  (define-symbolic* any-lsa-gc i32)
  (define-symbolic* any-gc-prog i32)
  (list
    any-lsa-gc
    any-gc-prog))

(define (ndvar-recovery)
  (define-symbolic* any-n-used-blks i64)
  (list
    any-n-used-blks))
