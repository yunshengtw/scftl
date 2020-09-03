#lang rosette

(require serval/lib/core
         "./lib/llvm-extend.rkt"
         "./lib/flash.rkt"
         "./const.rkt"
         "./misc.rkt"
         "./util.rkt"
         "./predicate.rkt")

(provide (all-defined-out))

(define (loopinv-remap_valid_sectors mach flash mrs0 abst)
  (define block-p2l (find-block-by-name (machine-mregions mach) 'p2l))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define-symbolic la pa i32)
  (list
    (bvult idx (bv64 N_LAS))
    (forall
      (list pa)
      (=>
        (pa-valid? pa)
        (||
          (bveq (p2l (zext64 pa)) (bv32 N_LAS))
          (bvult (zext64 (p2l (zext64 pa))) idx))))
    (||
      (bveq (p2l (bv64 N_PAS)) (bv32 N_LAS))
      (bvult (zext64 (p2l (bv64 N_PAS))) idx))
    (forall
      (list pa)
      (=>
        (pa-valid? pa)
        (=>
          (bvult (zext64 (p2l (zext64 pa))) idx)
          (bveq pa (l2p (zext64 (p2l (zext64 pa))))))))
    (forall
      (list la pa)
      (=>
        (&&
          (bveq (p2l (zext64 pa)) (bv32 N_LAS))
          (bvult (zext64 la) idx)
          (pa-valid? pa))
        (! (bveq (l2p (zext64 la)) pa))))))

(define (loopexit-remap_valid_sectors mach flash mrs0 abst)
  (define block-p2l (find-block-by-name (machine-mregions mach) 'p2l))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define-symbolic la pa i32)
  (list
    (tagcond/desp 'loop null
      (forall
        (list pa)
        (=>
          (pa-valid? pa)
          (bvule (p2l (zext64 pa)) (bv32 N_LAS)))))
    (tagcond/desp 'loop null
      (bvule (p2l (bv64 N_PAS)) (bv32 N_LAS)))
    (tagcond/desp 'loop null
      (forall
        (list pa)
        (=>
          (pa-valid? pa)
          (=>
            (la-valid? (p2l (zext64 pa)))
            (bveq pa (l2p (zext64 (p2l (zext64 pa)))))))))
    (tagcond/desp 'loopz null
      (forall
        (list la pa)
        (=>
          (&&
            (bveq (p2l (zext64 pa)) (bv32 N_LAS))
            (la-valid? la)
            (pa-valid? pa))
          (! (bveq (l2p (zext64 la)) pa)))))))

(define (loopcond-remap_valid_sectors mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (! (bveq idx (bv64 N_LAS))))

(define (loopinv-invalidate_p2l mach flash mrs0 abst)
  (define block-p2l (find-block-by-name (machine-mregions mach) 'p2l))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define-symbolic i i64)
  (list
    (bvule idx (bv64 N_PAS))
    (forall
      (list i)
      (=>
        (bvult i idx)
        (bveq (p2l i) (bv32 N_LAS))))))

(define (loopexit-invalidate_p2l mach flash mrs0 abst)
  (define block-p2l (find-block-by-name (machine-mregions mach) 'p2l))
  (define p2l (lambda (x) (mblock-iload block-p2l (list x))))
  (define-symbolic i i64)
  (list
    (tagcond/desp 'loop null
      (forall
        (list i)
        (=>
          (bvule i (bv64 N_PAS))
          (bveq (p2l i) (bv32 N_LAS)))))))

(define (loopcond-invalidate_p2l mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (! (bveq idx (bv64 (+ N_PAS 1)))))

(define (loopinv-apply_delta_chkpt mach flash mrs0 abst)
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define block-pba_committed (find-block-by-name (machine-mregions mach) 'pba_committed))
  (define pba_committed (mblock-iload block-pba_committed null))
  (define block-ipa_committed (find-block-by-name (machine-mregions mach) 'ipa_committed))
  (define ipa_committed (mblock-iload block-ipa_committed null))
  (define block-l2p0 (find-block-by-name mrs0 'l2p))
  (define l2p0 (lambda (x) (mblock-iload block-l2p0 (list x))))
  (define block-buf_tmp (find-block-by-name (machine-mregions mach) 'buf_tmp))
  (define buf_tmp (lambda (x) (mblock-iload block-buf_tmp (list x))))
  ; loop induction variable
  (define block-blkid (find-block-by-name (machine-mregions mach) 'blkid))
  (define blkid (mblock-iload block-blkid null))
  (define block-pgid (find-block-by-name (machine-mregions mach) 'pgid))
  (define pgid (mblock-iload block-pgid null))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
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
  (define-symbolic i i64)
  (define-symbolic la i32)
  (define-symbolic b p i32)
  (define-symbolic o i64)
  (list
    (bvult blkid (bv32 BLOCKS_DELTA))
    (bvult pgid (bv32 PAGES_PER_BLOCK))
    (bvult idx (bv64 N_DELTA_PAIR))
    (forall
      (list b p o)
      (=>
        (&&
          (bvult o (bv64 N_DELTA_PAIR))
          (||
            (&& (bvult b pba_committed) (bvult p (bv32 PAGES_PER_BLOCK)))
            (&& (bveq b pba_committed) (bvult p ipa_committed))))
        (bvule (data b p (offset-las o)) (bv32 N_LAS))))
    (=>
      (! (bveq idx (bv64 0)))
      (forall
        (list i)
        (=>
          (bvult i (bv64 N_ENTRIES_PER_PAGE))
          (bveq (buf_tmp i) (data blkid pgid i)))))
    ; committed point
    (||
      (&&
        (bveq pba_committed pba-commit)
        (bveq ipa_committed ipa-commit))
      (&&
        (bveq ipa_committed (bv32 PAGES_PER_BLOCK))
        (! (bveq pba-commit (bv32 0)))
        (bveq ipa-commit (bv32 0))
        (bveq pba-commit (bvadd pba_committed (bv32 1))))
      (&&
        (bveq ipa-commit (bv32 PAGES_PER_BLOCK))
        (! (bveq pba_committed (bv32 0)))
        (bveq ipa_committed (bv32 0))
        (bveq pba_committed (bvadd pba-commit (bv32 1)))))
    (bvule ipa-commit (bv PAGES_PER_BLOCK 32))
    (bvult pba-commit (bv BLOCKS_DELTA 32))
    (||
      (ar-cr-all-uncommitted-after-commit data synced pba-commit ipa-commit)
      (cr-committed-point-stop data pba-commit ipa-commit))
    (ar-cr-prev-committed-point-is-committed data pba-commit ipa-commit)
    ; map and delta chkpt
    (forall
      (list la)
      (=>
        (la-valid? la)
        (&&
          (=>
            (la-in-delta? la data pba-commit ipa-commit)
            (map-delta-consistent la data pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable))
          (=>
            (! (la-in-delta? la data pba-commit ipa-commit))
            (la-not-in-delta la map-pba-stable map-ipa-stable map-ptr-stable))
          (=>
            (&&
              (! (bveq (map-ptr-stable la) (bv N_DELTA_PAIR 64)))
              (||
                (bvult (map-pba-stable la) blkid)
                (&& (bveq (map-pba-stable la) blkid) (bvult (map-ipa-stable la) pgid))
                (&& (bveq (map-pba-stable la) blkid) (bveq (map-ipa-stable la) pgid) (bvult (map-ptr-stable la) idx))))
            (map-partial-l2p-consistent la data l2p map-pba-stable map-ipa-stable map-ptr-stable))
          (=>
            (bveq (map-ptr-stable la) (bv N_DELTA_PAIR 64))
            (l2p-l2p0-consistent la l2p l2p0)))))))

(define (loopexit-apply_delta_chkpt mach flash mrs0 abst)
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define block-l2p0 (find-block-by-name mrs0 'l2p))
  (define l2p0 (lambda (x) (mblock-iload block-l2p0 (list x))))
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
  (define-symbolic la i32)
  (list
    (tagcond/desp 'loop null
      (forall
        (list la)
        (=>
          (la-valid? la)
          (&&
            (=>
              (! (bveq (map-ptr-stable la) (bv N_DELTA_PAIR 64)))
              (map-partial-l2p-consistent la data l2p map-pba-stable map-ipa-stable map-ptr-stable))
            (=>
              (bveq (map-ptr-stable la) (bv N_DELTA_PAIR 64))
              (l2p-l2p0-consistent la l2p l2p0))))))))

(define (loopcond-apply_delta_chkpt mach)
  (define block-blkid (find-block-by-name (machine-mregions mach) 'blkid))
  (define blkid (mblock-iload block-blkid null))
  (! (bveq blkid (bv32 BLOCKS_DELTA))))

(define (inv-uncommitted-after-commit delta pba_committed ipa_committed blkid pgid)
  (define-symbolic b p i32)
  (forall
    (list b p)
    (=>
      (&&
        (||
          (&&
            (bvult pba_committed b)
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (&&
            (bveq pba_committed b)
            (bvule ipa_committed p)))
        (||
          (&&
            (bvult b blkid)
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (&&
            (bveq b blkid)
            (bvult p pgid))))
      (! (bveq (delta b p (bv64 0)) (bv32 0))))))

(define (exit-uncommitted-after-commit delta pba_committed ipa_committed)
  (define-symbolic b p i32)
  (forall
    (list b p)
    (=>
      (||
        (&&
          (bvult pba_committed b)
          (bvult b (bv32 BLOCKS_DELTA))
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (&&
          (bveq b pba_committed)
          (bvule ipa_committed p)
          (bvult p (bv32 PAGES_PER_BLOCK))))
      (! (bveq (delta b p (bv64 0)) (bv32 0))))))

(define (loopinv-find_last_committed_delta_chkpt mach flash mrs0 abst)
  (define block-blkid (find-block-by-name (machine-mregions mach) 'blkid))
  (define blkid (mblock-iload block-blkid null))
  (define block-pgid (find-block-by-name (machine-mregions mach) 'pgid))
  (define pgid (mblock-iload block-pgid null))
  (define block-pba_committed (find-block-by-name (machine-mregions mach) 'pba_committed))
  (define pba_committed (mblock-iload block-pba_committed null))
  (define block-ipa_committed (find-block-by-name (machine-mregions mach) 'ipa_committed))
  (define ipa_committed (mblock-iload block-ipa_committed null))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (list
    (bvult pgid (bv32 PAGES_PER_BLOCK))
    (bvult blkid (bv32 BLOCKS_DELTA))
    (||
      (&&
        (bvult pba_committed blkid)
        (bvule ipa_committed (bv32 PAGES_PER_BLOCK)))
      (&&
        (bveq pba_committed blkid)
        (bvule ipa_committed pgid)))
    (inv-uncommitted-after-commit data pba_committed ipa_committed blkid pgid)
    (ar-cr-prev-committed-point-is-committed data pba_committed ipa_committed)))

(define (loopexit-find_last_committed_delta_chkpt mach flash mrs0 abst)
  (define block-pba_committed (find-block-by-name (machine-mregions mach) 'pba_committed))
  (define pba_committed (mblock-iload block-pba_committed null))
  (define block-ipa_committed (find-block-by-name (machine-mregions mach) 'ipa_committed))
  (define ipa_committed (mblock-iload block-ipa_committed null))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (list
    (tagcond/desp 'loop null
      (bvule ipa_committed (bv PAGES_PER_BLOCK 32)))
    (tagcond/desp 'loop null
      (bvult pba_committed (bv BLOCKS_DELTA 32)))
    (tagcond/desp 'loop null
      (exit-uncommitted-after-commit data pba_committed ipa_committed))
    (tagcond/desp 'loop null
      (ar-cr-prev-committed-point-is-committed data pba_committed ipa_committed))))

(define (loopcond-find_last_committed_delta_chkpt mach)
  (define block-blkid (find-block-by-name (machine-mregions mach) 'blkid))
  (define blkid (mblock-iload block-blkid null))
  (! (bveq blkid (bv32 BLOCKS_DELTA))))

(define (loopinv-invalidate_delta_buf mach flash mrs0 abst)
  (define block-delta_buf (find-block-by-name (machine-mregions mach) 'delta_buf))
  (define delta_buf (lambda (x) (mblock-iload block-delta_buf (list x))))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define-symbolic i i64)
  (list
    (bvule (bv64 OFFSET_LAS) idx)
    (bvult idx (bv64 (+ OFFSET_LAS N_DELTA_PAIR)))
    (forall
      (list i)
      (=>
        (&&
          (bvule (bv64 OFFSET_LAS) i)
          (bvult i idx))
        (bveq (delta_buf i) (bv32 N_LAS))))))

(define (loopexit-invalidate_delta_buf mach flash mrs0 abst)
  (define block-delta_buf (find-block-by-name (machine-mregions mach) 'delta_buf))
  (define delta_buf (lambda (x) (mblock-iload block-delta_buf (list x))))
  (define-symbolic i i64)
  (list
    (tagcond/desp 'loop null
      (forall
        (list i)
        (=>
          (&&
            (bvule (bv64 OFFSET_LAS) i)
            (bvult i (bv64 (+ OFFSET_LAS N_DELTA_PAIR))))
          (bveq (delta_buf i) (bv32 N_LAS)))))))

(define (loopcond-invalidate_delta_buf mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (! (bveq idx (bv64 (+ OFFSET_LAS N_DELTA_PAIR)))))

(define (loopinv-categorize_used_and_erasable_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define block-blkid (find-block-by-name (machine-mregions mach) 'blkid))
  (define blkid (mblock-iload block-blkid null))
  (define block-is_used (find-block-by-name (machine-mregions mach) 'is_used))
  (define is_used (lambda (x) (mblock-iload block-is_used (list x))))
  (define-symbolic la pa i32)
  (define-symbolic i j i64)
  (define-symbolic p s i32)
  (list
    ; pointer constraint
    (bvult idx (bv64 BLOCKS_DATA))
    (bvule (bv32 PBA_DATA) blkid)
    (bvult blkid (bv32 (+ PBA_DATA BLOCKS_DATA)))
    (bvule erasable idx)
    (bveq (zext64 blkid) (bvadd idx (bv64 PBA_DATA)))
    ; is_used[i] implies that (i + PBA_DATA) does not appear in l2p
    (forall
      (list i la)
      (=>
        (&&
          (bvult i (bv64 BLOCKS_DATA))
          (la-valid? la))
        (=>
          (bveq (is_used i) (bv 0 8))
          (! (bveq (bvadd i (bv64 PBA_DATA)) (zext64 (psa->pba (l2p (zext64 la)))))))))
    ; elements in block list are unique
    (forall
      (list i j)
      (=>
        (&&
          (bvult i idx)
          (bvult j idx)
          (! (bveq i j)))
        (! (bveq (blk_list i) (blk_list j)))))
    ; elements in block list are within data range
    (forall
      (list i)
      (=>
        (bvult i idx)
        (&&
          (bvule (bv32 PBA_DATA) (blk_list i))
          (bvult (blk_list i) blkid))))
    ; erasable blocks are not mapped by l2p
    (forall
      (list i la)
      (=>
        (&&
          (bvule erasable i)
          (bvult i idx)
          (la-valid? la))
        (! (bveq (blk_list i) (psa->pba (l2p (zext64 la)))))))))
    
(define (loopexit-categorize_used_and_erasable_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define-symbolic la i32)
  (define-symbolic i j i64)
  (define-symbolic p i32)
  ; elements in block list are unique
  (list
    (tagcond/desp 'loop null
      (bvule erasable (bv64 BLOCKS_DATA)))
    (tagcond/desp 'loop null
      (forall
        (list i j)
        (=>
          (&&
            (blklist-ptr-valid? i)
            (blklist-ptr-valid? j)
            (! (bveq i j)))
          (! (bveq (blk_list i) (blk_list j))))))
      ; elements in block list are within data range
    (tagcond/desp 'loop null
      (forall
        (list i)
        (=>
          (blklist-ptr-valid? i)
          (&&
            (bvule (bv32 PBA_DATA) (blk_list i))
            (bvult (blk_list i) (bv32 (+ PBA_DATA BLOCKS_DATA)))))))
      ; usable blocks are not mapped by l2p
    (tagcond/desp 'loop null
      (forall
        (list i la)
        (=>
          (&&
            (bvule erasable i)
            (bvult i (bv64 BLOCKS_DATA))
            (la-valid? la))
          (! (bveq (blk_list i) (psa->pba (l2p (zext64 la))))))))))
    
(define (loopcond-categorize_used_and_erasable_blocks mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (! (bveq idx (bv64 BLOCKS_DATA))))

(define (loopinv-identify_used_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (define block-is_used (find-block-by-name (machine-mregions mach) 'is_used))
  (define is_used (lambda (x) (mblock-iload block-is_used (list x))))
  (define-symbolic la i32)
  (define-symbolic i i64)
  (list
    ; precondition
    (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range (zext64 la) l2p)))
    ; pointer constraint
    (bvult sectid (bv32 N_LAS))
    ; is_used[i] implies that (i + PBA_DATA) does not appear in l2p
    (forall
      (list i la)
      (=>
        (&&
          (bvult i (bv64 BLOCKS_DATA))
          (bvult la sectid))
        (=>
          (bveq (is_used i) (bv 0 8))
          (! (bveq (bvadd i (bv64 PBA_DATA)) (zext64 (psa->pba (l2p (zext64 la)))))))))
    ))
    
(define (loopexit-identify_used_blocks mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-is_used (find-block-by-name (machine-mregions mach) 'is_used))
  (define is_used (lambda (x) (mblock-iload block-is_used (list x))))
  (define-symbolic la i32)
  (define-symbolic i i64)
  ; elements in block list are unique
  (list
    (tagcond/desp 'loop null
      (forall
        (list i la)
        (=>
          (&&
            (bvult i (bv64 BLOCKS_DATA))
            (la-valid? la))
          (=>
            (bveq (is_used i) (bv 0 8))
            (! (bveq (bvadd i (bv64 PBA_DATA)) (zext64 (psa->pba (l2p (zext64 la))))))))))))
    
(define (loopcond-identify_used_blocks mach)
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (! (bveq sectid (bv32 N_LAS))))

(define (loopinv-find_index_of_victim_block mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define block-idx_victim (find-block-by-name (machine-mregions mach) 'idx_victim))
  (define idx_victim (mblock-iload block-idx_victim null))
  (define block-min_vcnt (find-block-by-name (machine-mregions mach) 'min_vcnt))
  (define min_vcnt (mblock-iload block-min_vcnt null))
  (define block-vcnts (find-block-by-name (machine-mregions mach) 'vcnts))
  (define vcnts (lambda (x) (mblock-iload block-vcnts (list x))))
  (define-symbolic i i64)
  (list
    (bvult used (bv64 BLOCKS_DATA))
    (bvult active (bv64 BLOCKS_DATA))
    (blklist-used? idx used active)
    (blklist-used? idx_victim used active)
    (bveq min_vcnt (vcnts (zext64 (blk_list idx_victim))))
    (forall
      (list i)
      (=>
        (blklist-ptr-valid? i)
        (&&
          (bvule (bv32 PBA_DATA) (blk_list i))
          (bvult (blk_list i) (bv32 (+ PBA_DATA BLOCKS_DATA))))))
    (forall
      (list i)
      (=>
        (blklist-generic i used idx)
        (bvule
          (vcnts (zext64 (blk_list idx_victim)))
          (vcnts (zext64 (blk_list i))))))
    ))
    
(define (loopexit-find_index_of_victim_block mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-idx_victim (find-block-by-name (machine-mregions mach) 'idx_victim))
  (define idx_victim (mblock-iload block-idx_victim null))
  (define block-vcnts (find-block-by-name (machine-mregions mach) 'vcnts))
  (define vcnts (lambda (x) (mblock-iload block-vcnts (list x))))
  (define-symbolic i i64)
  (list
    (tagcond/desp 'loop null
      ; idx_victim points to a used block
      (blklist-used? idx_victim used active))
    (tagcond/desp 'loop null
      ; idx_victim points to the one with minimum valid sectors
      (forall
        (list i)
        (=>
          (blklist-used? i used active)
          (bvule
            (vcnts (zext64 (blk_list idx_victim)))
            (vcnts (zext64 (blk_list i)))))))))
    
(define (loopcond-find_index_of_victim_block mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define block-active (find-block-by-name (machine-mregions mach) 'active))
  (define active (mblock-iload block-active null))
  (! (bveq idx active)))

(define (loopinv-reset_vcnts mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (define block-vcnts (find-block-by-name (machine-mregions mach) 'vcnts))
  (define vcnts (lambda (x) (mblock-iload block-vcnts (list x))))
  (define-symbolic i i64)
  (list
    (bvult idx (bv64 BLOCKS_TOTAL))
    (forall
      (list i)
      (=>
        (bvult i idx)
        (bveq (vcnts i) (bv16 0))))))
    
(define (loopexit-reset_vcnts mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define block-vcnts (find-block-by-name (machine-mregions mach) 'vcnts))
  (define vcnts (lambda (x) (mblock-iload block-vcnts (list x))))
  (define-symbolic i i64)
  null)
    
(define (loopcond-reset_vcnts mach)
  (define block-idx (find-block-by-name (machine-mregions mach) 'idx))
  (define idx (mblock-iload block-idx null))
  (! (bveq idx (bv64 BLOCKS_TOTAL))))

(define (loopinv-count_valid_sectors mach flash mrs0 abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (define-symbolic i i64)
  (define-symbolic la i32)
  (list
    (bvult sectid (bv32 N_LAS))
    (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range (zext64 la) l2p)))))
    
(define (loopexit-count_valid_sectors mach flash mrs0 abst)
  ; we dont need exit condition for vcnts
  null)

(define (loopcond-count_valid_sectors mach)
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (! (bveq sectid (bv32 N_LAS))))

(define (loopinv-check_l2p_injective mach flash mrs0 abst)
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (define block-failed (find-block-by-name (machine-mregions mach) 'failed))
  (define failed (mblock-iload block-failed null))
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define block-pa_used (find-block-by-name (machine-mregions mach) 'pa_used))
  (define pa_used (lambda (x) (mblock-iload block-pa_used (list x))))
  (define-symbolic i i64)
  (define-symbolic la la2 i32)
  (list
    (bvult sectid (bv32 N_LAS))
    (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range (zext64 la) l2p)))
    (forall
      (list la)
      (=>
        (bvult la sectid)
        (bveq (pa_used (zext64 (l2p (zext64 la)))) (bv 1 8))))
    (=>
      (bveq failed (bv32 0))
      (forall
        (list la la2)
        (=>
          (&&
            (! (bveq (l2p (zext64 la)) (bv32 N_PAS)))
            (! (bveq la la2))
            (bvult la sectid)
            (bvult la2 sectid))
          (! (bveq (l2p (zext64 la)) (l2p (zext64 la2)))))))))

(define (loopexit-check_l2p_injective mach flash mrs0 abst)
  (define block-l2p (find-block-by-name (machine-mregions mach) 'l2p))
  (define l2p (lambda (x) (mblock-iload block-l2p (list x))))
  (define-symbolic la la2 i32)
  (list
    (tagcond/desp 'loop null
      (forall
        (list la la2)
        (=>
          (&&
            (! (bveq (l2p (zext64 la)) (bv32 N_PAS)))
            (! (bveq la la2))
            (la-valid? la)
            (la-valid? la2))
          (! (bveq (l2p (zext64 la)) (l2p (zext64 la2)))))))))
  
(define (loopcond-check_l2p_injective mach)
  (define block-sectid (find-block-by-name (machine-mregions mach) 'sectid))
  (define sectid (mblock-iload block-sectid null))
  (! (bveq sectid (bv32 N_LAS))))
