#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         racket/struct
         rosette/lib/roseunit
         rosette/solver/smt/z3
         serval/lib/unittest
         serval/lib/debug
         serval/lib/core)

(require "./lib/flash.rkt"
         "./lib/llvm-extend.rkt"
         "./spec.rkt"
         "./loop.rkt"
         "./method.rkt"
         "./misc.rkt"
         "./util.rkt"
         "./const.rkt"
         "./partition.rkt"
         "./inv-rel.rkt")

(require "./generated/ftl.globals.rkt"
         "./generated/ftl.map.rkt"
         "./generated/ftl.ll.rkt")

(define (check-operation op)
  (define args (operation-args op))
  (define inv-pre (operation-inv-pre op))
  (define rel-pre (operation-rel-pre op))
  (define cr-partition (operation-cr-partition op))
  (define ndvar ((operation-ndvar-gen op)))

  ; impl state
  (define mach (make-machine symbols globals))
  (define flash (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))

  ; spec state
  (define abst (make-abstract))

  ; copy state for debug
  (define mrs-copied (map mregion-copy (machine-mregions mach)))
  (define flash-copied (copy-flash flash))
  (define abst-copied (struct-copy abstract abst))

  (parameterize
    ([current-machine mach]
     [current-flash flash]
     [current-mregions-saved (map mregion-copy (machine-mregions mach))]
     [current-abst (struct-copy abstract abst)]
     [current-methods methods]
     [current-loops loops]
     ; [current-solver (z3 #:path "/usr/local/bin/z3" #:options (hash ':auto-config 'false ':smt.relevancy 0))]
     [snapshots null]
     [assumes null])
    (define inv0 (inv-pre mach flash))
    (assume inv0)

    (define-values (rel0 rel0-asserted)
      (with-asserts (rel-pre mach flash abst)))
    (check-equal? rel0-asserted null)
    (assume rel0)

    (define-values (crp crp-asserted)
      (with-asserts (cr-partition (machine-mregions mach))))
    (check-equal? crp-asserted null)

    ; spec transition; return a list of crash states
    (define crash-absts (apply (operation-spec op) abst ndvar args))
    (check-equal? (asserts) null)

    ; impl transition
    (define impl-asserted
      (with-asserts-only (apply (operation-proc op) args)))
    (flash-snapshot)
    (printf "Number of crash snapshot: ~e\n" (length (snapshots)))

    ; (for-each (compose println car) (snapshots))
    (check-equal? (length (snapshots)) (length crp))

    (define assumed (apply && (map cdr (assumes))))

    (printf "Number of side conditions: ~e\n" (length impl-asserted))
    (define cex-impl (verify (assert (=> assumed (apply && impl-asserted)))))
    (check-unsat? cex-impl)
    (printf "Side conditions checked\n")

    (define-values (ri ri-asserted)
      (with-asserts (rep-inv mach flash)))
    (check-unsat? (verify (assert (=> assumed (apply && ri-asserted)))))

    (define-values (ar ar-asserted)
      (with-asserts (abs-rel mach flash abst)))
    (check-unsat? (verify (assert (=> assumed (apply && ar-asserted)))))

    (for ([s (snapshots)]) (crash-flash (cdr s)))

    (define-values (ci ci-asserted)
      (with-asserts
        (map (lambda (s) (crash-inv mach (cdr s))) (snapshots))))
    (check-unsat? (verify (assert (=> assumed (apply && ci-asserted)))))

    (define-values (cr cr-asserted)
      (with-asserts (for/list ([s (snapshots)])
        (define c (cdr s))
        (map
          (lambda (a) (crash-rel mach c a))
          crash-absts))))
    (check-unsat? (verify (assert (=> assumed (apply && cr-asserted)))))

    (printf "Checking RI\n")
    (for ([tc ri])
      (printf "~a" (tagcond-desp tc))
      (let* ([premises (required-conjuncts (assumes) (tagcond-require tc))]
             [conclusion (tagcond-cond tc)]
             [cex-ri (verify (assert (=> premises conclusion)))])
        (check-unsat? cex-ri)
        (printf " [Proved]\n")))
    (printf "RI holds\n")

    (printf "Checking AR\n")
    (for ([tc ar])
      (printf "~a" (tagcond-desp tc))
      (let* ([premises (required-conjuncts (assumes) (tagcond-require tc))]
             [conclusion (tagcond-cond tc)]
             [cex-ar (verify (assert (exists ndvar (=> premises conclusion))))])
        (check-unsat? cex-ar)
        (printf " [Proved]\n")))
    (printf "AR holds\n")

    (printf "Checking CI\n")
    (for ([c ci]
          [s (snapshots)]
          [csid (length ci)])
      (printf "Proving crash state ~a\n" csid)
      (for ([tc c])
        (printf "~a" (tagcond-desp tc))
        (let* ([cspc (car s)]
               [premises (required-conjuncts (assumes) (tagcond-require tc))]
               [conclusion (tagcond-cond tc)]
               [cex-ci (verify (assert (=> (&& cspc premises) conclusion)))])
          (check-unsat? cex-ci)
          (printf " [Proved]\n"))))
    (printf "CI holds\n")

    (printf "Checking CR\n")
    ; for each crash state
    (for ([c cr]
          [ps crp]
          [s (snapshots)]
          [csid (length cr)])
      ; for each initial state partition
      (for ([p ps]
            [ispid (length ps)])
        (printf "Proving crash state ~a under initial state partition ~a\n" csid ispid)
        ; for each conjunct
        (for ([tc (list-ref c (car p))])
          (printf "~a" (tagcond-desp tc))
          (let* ([cspc (car s)]
                 [isp (cdr p)]
                 [premises (required-conjuncts (assumes) (tagcond-require tc))]
                 [conclusion (tagcond-cond tc)]
                 [cex-cr (verify (assert (=> (&& cspc isp premises) conclusion)))])
            (check-unsat? cex-cr)
            (printf " [Proved]\n")))))
    (printf "CR holds\n")
    ))

(define (check-obs-equiv)
  ; impl state
  (define mach (make-machine symbols globals))
  (define flash (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))
  (define snapshot (copy-flash flash))

  ; spec state
  (define abst (make-abstract))

  (parameterize
    ([current-machine mach]
     [current-flash flash]
     [current-mregions-saved (map mregion-copy (machine-mregions mach))]
     [current-abst (struct-copy abstract abst)]
     [current-methods methods]
     [current-loops loops]
     ; [current-solver (z3 #:path "/usr/local/bin/z3" #:options (hash ':auto-config 'false ':smt.relevancy 0))]
     [snapshots null])
    (define ri (rep-inv mach flash))

    (define-values (ar ar-asserted)
      (with-asserts (abs-rel mach flash abst)))
    (check-equal? ar-asserted null)

    (define pre (apply && (append (map tagcond-cond ri) (map tagcond-cond ar))))

    (define lsa (make-bv32))
    (define data-pointer (host-data-pointer))

    (define data-spec (spec-read abst lsa))
    (check-equal? (asserts) null)

    ; impl transition
    (define impl-asserted
      (with-asserts-only (@ftl_read lsa data-pointer)))
    (printf "Number of side conditions: ~e\n" (length impl-asserted))
    (define cex-impl (verify (assert (=> pre (apply && impl-asserted)))))
    (check-unsat? cex-impl)
    (printf "Side conditions checked\n")

    (define data-impl (lambda (x) (mblock-iload (pointer-block data-pointer) (list x))))

    (define-symbolic offset i64)
    (define obs-equiv (forall
      (list offset)
      (=>
        (bvult offset (bv64 N_ENTRIES_PER_SECTOR))
        (bveq (data-spec offset) (data-impl offset)))))

    (define lsa-validity (bvult lsa (bv32 N_LAS)))
    (printf "Checking observational equivalence\n")
    (define cex-obs-equiv (verify (assert (=> (&& pre lsa-validity) obs-equiv))))
    (check-unsat? cex-obs-equiv)
    (printf "Observational equivalence checked\n")))

(define (check-format)
  ; impl state
  (define mach (make-machine symbols globals))
  (define flash (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))
  (define snapshot (copy-flash flash))

  ; spec state
  (define abst (make-abstract))

  (parameterize
    ([current-machine mach]
     [current-flash flash]
     [current-mregions-saved (map mregion-copy (machine-mregions mach))]
     [current-abst (struct-copy abstract abst)]
     [current-methods methods]
     [current-loops loops]
     [snapshots null])
    ; spec transition
    (spec-format abst)
    (check-equal? (asserts) null)

    ; impl transition
    (define impl-asserted
      (with-asserts-only (@ftl_format)))

    (printf "Number of side conditions: ~e\n" (length impl-asserted))
    (define cex-impl (verify (assert (apply && impl-asserted))))
    (check-unsat? cex-impl)
    (printf "Side conditions checked\n")

    ; (print-impl-abst-state (current-machine) (current-flash) abst)

    (define-values (ci ci-asserted)
      (with-asserts (crash-inv mach flash)))
    (check-unsat? (verify (assert (apply && ci-asserted))))

    (define-values (cr cr-asserted)
      (with-asserts (crash-rel mach flash abst)))
    (check-unsat? (verify (assert (apply && cr-asserted))))

    (printf "Checking CI\n")
    (for ([tc ci])
      (printf "~a" (tagcond-desp tc))
      (let* ([f (tagcond-cond tc)]
             [cex-ci (verify (assert f))])
        (check-unsat? cex-ci)
        (printf " [Proved]\n")))
    (printf "CI holds\n")

    (printf "Checking CR\n")
    (for ([tc cr])
      (printf "~a" (tagcond-desp tc))
      (let* ([f (tagcond-cond tc)]
             [cex-cr (verify (assert f))])
        (check-unsat? cex-cr)
        (printf " [Proved]\n")))
    (printf "CR holds\n")
    ))

(define (check-method method)
  (define proc (method-proc method))
  (define args (method-args method))
  (define precond (method-precond method))
  (define postcond (method-postcond method))
  (define havocs (method-havocs method))

  ; impl state
  (define mach (make-machine symbols globals))
  (define flash (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))
  (define mrs0 (map mregion-copy (machine-mregions mach)))

  ; spec state
  (define abst (make-abstract))

  ; copy state for debug
  (define mrs-copied (map mregion-copy (machine-mregions mach)))
  (define flash-copied (copy-flash flash))
  (define abst-copied (struct-copy abstract abst))

  (parameterize
    ([current-machine mach]
     [current-flash flash])
    (define pre (precond mach flash mrs0 abst))

    ; impl transition
    (define impl-asserted
      (with-asserts-only (apply proc args)))

    (printf "Number of side conditions: ~e\n" (length impl-asserted))
    (define cex-impl (verify (assert (=> pre (apply && impl-asserted)))))
    (check-unsat? cex-impl)
    (printf "Side conditions checked\n")

    (define-values (post post-asserted)
      (with-asserts
        (let* ([tcs (postcond mach flash mrs0 abst)]
               [c (apply && (map tagcond-cond tcs))])
          (if (method-check method) (gen-valcond c mach) c))))
    (check-unsat? (verify (assert (=> pre (apply && post-asserted)))))

    ; check if the invariant holds
    (printf "Checking method specification\n")
    (define cex (verify (assert (=> pre post))))
    ; (when
    ;   (sat? cex)
    ;   (cex-handler cex (machine-mregions mach) flash abst mrs-copied flash-copied abst-copied))
    (check-unsat? cex)
    (printf "Method specification verified\n")))

(define (check-loop loop)
  (define bodyproc (loop-bodyproc loop))
  (define loopinv (loop-inv loop))
  (define loopexit (loop-exit loop))
  (define loopcond (loop-condition loop))
  (define havocs (loop-havocs loop))

  ; s0
  (define mach0 (make-machine symbols globals))
  (define flash0 (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))
  (define mrs0 (machine-mregions mach0))

  ; s
  (define mach (make-machine symbols globals))
  (define flash (make-flash (+ BLOCKS_TOTAL 1) PAGES_PER_BLOCK (* N_ENTRIES_PER_PAGE 4)))

  ; spec state
  (define abst (make-abstract))

  ; copy state for debug
  (define mrs-copied (map mregion-copy (machine-mregions mach)))
  (define flash-copied (copy-flash flash))
  (define abst-copied (struct-copy abstract abst))

  (parameterize
    ([current-machine mach]
     [current-flash flash])
    (define pre (&&
      (loopcond mach)
      (apply && (loopinv mach flash mrs0 abst))))

    ; impl transition
    (define impl-asserted
      (with-asserts-only (bodyproc)))

    (printf "Number of side conditions: ~e\n" (length impl-asserted))
    (define cex-impl (verify (assert (=> pre (apply && impl-asserted)))))
    (check-unsat? cex-impl)
    (printf "Side conditions checked\n")

    (define-values (inv inv-asserted)
      (with-asserts (loopinv mach flash mrs0 abst)))
    (check-unsat? (verify (assert (=> pre (apply && inv-asserted)))))

    (define-values (exit exit-asserted)
      (with-asserts
        (let* ([tcs (loopexit mach flash mrs0 abst)]
               [c (apply && (map tagcond-cond tcs))])
          (if (loop-check loop) (gen-valcond c mach) c))))
    (check-unsat? (verify (assert (=> pre (apply && exit-asserted)))))

    (define-values (condition condition-asserted)
      (with-asserts (loopcond mach)))
    (check-unsat? (verify (assert (=> pre (apply && condition-asserted)))))

    ; (!cond /\ exit) \/ (cond /\ (inv0 /\ inv1))
    ; <-> (!cond /\ exit) \/ ((cond /\ inv0) /\ (cond /\ inv1))
    ; { Disjunctions distribute over conjunctions }
    ; <-> ((!cond /\ exit) \/ (cond /\ inv0)) /\ ((!cond /\ exit) \/ (cond /\ inv1))
    (for ([x inv])
      (let ([post (|| (&& (! condition) exit) (&& condition x))])
        (check-unsat? (verify (assert (=> pre post))))))

    (printf "Loop specification verified\n")))

(define methods (list
  (method @check_sufficient_avail_blocks null
          pre-check_sufficient_avail_blocks post-check_sufficient_avail_blocks
          null #t)
  (method @check_sufficient_ready_blocks null
          pre-check_sufficient_ready_blocks post-check_sufficient_ready_blocks
          null #t)))

(define loops (list
  (loop @count_valid_sectors_loop @count_valid_sectors_body
        loopinv-count_valid_sectors
        loopexit-count_valid_sectors
        loopcond-count_valid_sectors
        (list 'idx 'vcnts) #f)
  (loop @reset_vcnts_loop @reset_vcnts_body
        loopinv-reset_vcnts
        loopexit-reset_vcnts
        loopcond-reset_vcnts
        (list 'idx 'vcnts) #f)
  (loop @find_index_of_victim_block_loop @find_index_of_victim_block_body
        loopinv-find_index_of_victim_block
        loopexit-find_index_of_victim_block
        loopcond-find_index_of_victim_block
        (list 'idx 'idx_victim 'min_vcnt) #f)
  (loop @categorize_used_and_erasable_blocks_loop @categorize_used_and_erasable_blocks_body
        loopinv-categorize_used_and_erasable_blocks
        loopexit-categorize_used_and_erasable_blocks
        loopcond-categorize_used_and_erasable_blocks
        (list 'blk_list 'idx 'blkid 'erasable) #f)
  (loop @identify_used_blocks_loop @identify_used_blocks_body
        loopinv-identify_used_blocks
        loopexit-identify_used_blocks
        loopcond-identify_used_blocks
        (list 'sectid 'is_used) #f)
  (loop @remap_valid_sectors_loop @remap_valid_sectors_body
        loopinv-remap_valid_sectors
        loopexit-remap_valid_sectors
        loopcond-remap_valid_sectors
        (list 'p2l 'idx) #f)
  (loop @invalidate_p2l_loop @invalidate_p2l_body
        loopinv-invalidate_p2l
        loopexit-invalidate_p2l
        loopcond-invalidate_p2l
        (list 'p2l 'idx) #f)
  (loop @apply_delta_chkpt_loop @apply_delta_chkpt_body
        loopinv-apply_delta_chkpt
        loopexit-apply_delta_chkpt
        loopcond-apply_delta_chkpt
        (list 'l2p 'buf_tmp 'blkid 'pgid 'idx) #f)
  (loop @find_last_committed_delta_chkpt_loop @find_last_committed_delta_chkpt_body
        loopinv-find_last_committed_delta_chkpt
        loopexit-find_last_committed_delta_chkpt
        loopcond-find_last_committed_delta_chkpt
        (list 'pba_committed 'ipa_committed 'buf_tmp 'blkid 'pgid 'idx) #f)
  (loop @invalidate_delta_buf_loop @invalidate_delta_buf_body
        loopinv-invalidate_delta_buf
        loopexit-invalidate_delta_buf
        loopcond-invalidate_delta_buf
        (list 'delta_buf) #f)
  (loop @check_l2p_injective_loop @check_l2p_injective_body
        loopinv-check_l2p_injective
        loopexit-check_l2p_injective
        loopcond-check_l2p_injective
        (list 'failed 'pa_used 'sectid) #t)))

(struct operation (proc spec args inv-pre rel-pre cr-partition ndvar-gen))

(define operations (list
  (operation @ftl_write spec-write (list (make-bv32) (host-data-pointer))
             rep-inv abs-rel cr-partition-write ndvar-null)
  (operation @ftl_flush spec-flush null
             rep-inv abs-rel cr-partition-flush ndvar-null)
  (operation @ftl_gc_copy spec-gc_copy null
             rep-inv abs-rel cr-partition-gc_copy ndvar-gc_copy)
  (operation @ftl_gc_erase spec-gc_erase null
             rep-inv abs-rel cr-partition-gc_erase ndvar-null)
  (operation @ftl_recovery spec-recovery null
             crash-inv crash-rel cr-partition-recovery ndvar-recovery)
  ))

(define ftl-tests
  (test-suite+
    "Tests for ftl.c"

    ; check methods with specification
    (for-each
      (lambda (m) (test-case+ 
        (symbol->string (object-name (method-proc m))) 
        (check-method m)))
      methods)
    ; check loops with specification
    (for-each
      (lambda (l) (test-case+ 
        (symbol->string (object-name (loop-proc l))) 
        (check-loop l)))
      loops)
    ; check top-level operations
    (for-each
      (lambda (o) (test-case+ 
        (symbol->string (object-name (operation-proc o))) 
        (check-operation o)))
      operations)
    (test-case+ "Observational equivalence" (check-obs-equiv))
    (test-case+ "Initial consistency" (check-format))
    ))

(module+ test
  (time (run-tests ftl-tests)))
