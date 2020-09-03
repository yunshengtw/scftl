#lang rosette

(require serval/lib/core
         "./lib/flash.rkt"
         "./lib/llvm-extend.rkt"
         "./misc.rkt"
         "./util.rkt"
         "./const.rkt"
         "./predicate.rkt")

(provide (all-defined-out))

(define (rep-inv mach flash)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define-symbolic i j i64)
  (define-symbolic b p i32)
  (define-symbolic la la2 pa i32)
  (define psa_gc (pba-ipa-isa->psa pba_gc ipa_gc isa_gc))
  (list
    (tagcond/desp 'usable-not-in-l2p (list 'common 'blklist 'data 'usable-not-in-l2p 'loop 'loopz) (forall
      (list i la)
      (=>
        (&&
          (blklist-usable? i usable erasable)
          (la-valid? la))
        (! (bveq (blk_list i) (psa->pba (l2p (zext64 la)))))))
      "Sectors in usable blocks do not appear in L2P")
    (tagcond/desp 'active-right-half-not-in-l2p (list 'common 'blklist 'data 'usable-not-in-l2p 'active-right-half-not-in-l2p 'loop 'method) (forall
      (list la pa)
      (=>
        (&&
          (bvule (pba-ipa-isa->psa pba_active ipa_active isa_active) pa)
          (bvult pa (pba-ipa-isa->psa (bvadd pba_active (bv32 1)) (bv32 0) (bv32 0)))
          (la-valid? la))
        (! (bveq pa (l2p (zext64 la))))))
      "Sectors in the right half of the active block do not appear in L2P")
    (tagcond/desp 'l2p-unique #t (forall
      (list la la2)
      (=>
        (&&
          (! (bveq (l2p (zext64 la)) (bv32 N_PAS)))
          (! (bveq la la2))
          (la-valid? la)
          (la-valid? la2))
        (! (bveq (l2p (zext64 la)) (l2p (zext64 la2))))))
      "L2P is an one-to-one mapping except for invalid entries")
    (tagcond/desp 'invalid-pa-not-in-l2p (list 'loopz 'common 'blklist 'l2p-unique 'invalid-pa-not-in-l2p) (forall
      (list la pa)
      (=>
        (&&
          (bveq (p2l (zext64 pa)) (bv32 N_LAS))
          (la-valid? la)
          (pa-valid? pa))
        (! (bveq (l2p (zext64 la)) pa))))
      "Invalid entries of P2L do not appear in L2P")
    (tagcond/desp 'psa_gc-only-at-lsa_gc (list 'common 'data 'blklist 'l2p-unique 'invalid-pa-not-in-l2p 'gc 'loop) (=>
      (! (bveq enable_gc (bv32 0)))
      (forall
        (list la)
        (=>
          (&&
            (la-valid? la)
            (! (bveq la lsa_gc)))
          (! (bveq psa_gc (l2p (zext64 la)))))))
      "The PA of the victim sector is unique in L2P")
    (tagcond/desp 'victim-left-half-no-in-l2p (list 'common 'data 'blklist 'psa_gc-only-at-lsa_gc 'victim-left-half-no-in-l2p) (=>
      (! (bveq enable_gc (bv32 0)))
      (forall
        (list la pa)
        (=>
          (&&
            (bvule (pba-ipa-isa->psa pba_gc (bv32 0) (bv32 0)) pa)
            (bvult pa (pba-ipa-isa->psa pba_gc ipa_gc isa_gc))
            (la-valid? la))
          (! (bveq pa (l2p (zext64 la)))))))
      "Sectors in the left half of the victim block do not appear in L2P")
    (tagcond/desp 'common (list 'common 'blklist 'data 'l2p-unique) (=>
      (! (bveq enable_gc (bv32 0)))
      (bveq lsa_gc (p2l (zext64 psa_gc))))
      "P2L maps the PA of the victim sector to its LA")
    (tagcond/desp 'common (list 'common 'gc 'blklist 'loop) (=>
      (&&
        (! (bveq enable_gc (bv32 0)))
        (bvult lsa_gc (bv32 N_LAS)))
      (bveq psa_gc (l2p (zext64 lsa_gc))))
      "L2P maps the LA of the victim sector to its PA when the victim sector is valid")
    (tagcond/desp 'common #t (=>
      (! (bveq enable_gc (bv32 0)))
      (! (bveq pba_gc pba_active)))
      "The active data block and the victim block are distinct")
    (tagcond/desp 'common #t (=>
      (! (bveq enable_gc (bv32 0)))
      (bveq pba_gc (blk_list used)))
      "The victim block is the first block in the used block queue")
    (tagcond/desp 'common #t (bvule ptr_delta_buf (bv32 N_DELTA_PAIR))
      "The delta buffer pointer is less than or equal to the buffer capacity")
    (tagcond/desp 'common #t (bvule pba_delta (bv32 BLOCKS_DELTA))
      "The active delta block is within the delta region")
    (tagcond/desp 'common #t (bvule ipa_delta (bv32 PAGES_PER_BLOCK))
      "The active delta page is less than or equal to the number of pages per block")
    (tagcond/desp 'common #t (forall
      (list p)
      (=> (bvult p ipa_delta) (! (erased pba_delta p))))
      "Sectors in the left half of the active delta block are programmed")
    (tagcond/desp 'common #t (forall
      (list p)
      (=> (bvuge p ipa_delta) (erased pba_delta p)))
      "Sectors in the right half of the active delta block are erased")
    (tagcond/desp 'common #t (forall
      (list b p)
      (=>
        (&& (bvugt b pba_delta) (bvult b (bv32 PBA_DELTA_END)))
        (erased b p)))
      "Sectors in the right half of the delta region are erased")
    (tagcond/desp 'common #t (=>
      (bvuge pba_delta (bv32 THRESHOLD_DELTA_WB))
      (bvule
        (bvadd (bvmul (bvadd (bvmul (bvsub pba_delta (bv32 THRESHOLD_DELTA_WB)) (bv32 PAGES_PER_BLOCK)) ipa_delta) (bv32 N_DELTA_PAIR)) ptr_delta_buf)
        (bvadd wcnt gcprog)))
      "The delta region does not run out of space")
    (tagcond/desp 'common #t (bvule ptr_delta_buf (bvadd wcnt gcprog))
      "The active delta pointer is less than or equal to the total number of sectors due to writes and GCs in the current epoch")
    (tagcond/desp 'common #t (bvule wcnt (bv32 MAX_WCNT))
      "The number of sectors due to writes in one epoch does not exceed a certain limit")
    (tagcond/desp 'common #t (bvule gcprog (bv32 MAX_GCPROG))
      "The number of sectors due to GCs in one epoch does not exceed a certain limit")
    ; For flush
    (tagcond/desp 'common #t (bvult ptr_full (bv32 2))
      "The free full checkpoint pointer is either 0 or 1")
    (tagcond/desp 'common #t (=>
      (bveq ptr_full (bv32 0))
      (forall
        (list b p)
        (=>
          (&&
            (bvule (bv32 PBA_FIRST_FULL) b)
            (bvule b (bv32 PBA_FIRST_FULL_COMMIT))
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (erased b p))))
      "Blocks in the free full checkpoint region are erased (first region)")
    (tagcond/desp 'common #t (=>
      (bveq ptr_full (bv32 1))
      (forall
        (list b p)
        (=>
          (&&
            (bvule (bv32 PBA_SECOND_FULL) b)
            (bvule b (bv32 PBA_SECOND_FULL_COMMIT))
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (erased b p))))
      "Blocks in the free full checkpoint region are erased (second region)")
    (tagcond/desp 'blklist (list 'common 'blklist 'data 'loop) (forall
      (list i j)
      (=>
        (&&
          (blklist-ptr-valid? i)
          (blklist-ptr-valid? j)
          (! (bveq i j)))
        (! (bveq (blk_list i) (blk_list j)))))
      "The block list does not contain repeated elements")
    (tagcond/desp 'blklist #t (forall
      (list i)
      (=>
        (blklist-ptr-valid? i)
        (&&
          (bvule (bv32 PBA_DATA) (blk_list i))
          (bvult (blk_list i) (bv32 (+ PBA_DATA BLOCKS_DATA))))))
      "Blocks in the block list belong to the data region")
    (tagcond/desp 'blklist (list 'common 'blklist 'data 'loop) (forall
      (list i p)
      (=>
        (&&
          (blklist-usable? i usable erasable)
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (erased (blk_list i) p)))
      "Usable blocks are erased")
    (tagcond/desp 'blklist (list 'common 'blklist 'data 'loop) (forall
      (list i la)
      (=>
        (&&
          (blklist-erasable? i erasable invalid)
          (la-valid? la))
        (! (bveq (blk_list i) (psa->pba (l2p (zext64 la)))))))
      "Sectors in erasable blocks do not appear in L2P")
    (tagcond/desp 'blklist (list 'common 'data 'blklist 'psa_gc-only-at-lsa_gc 'victim-left-half-no-in-l2p 'loop) (forall
      (list i la)
      (=>
        (&&
          (blklist-invalid? i invalid used)
          (la-valid? la))
        (! (bveq (blk_list i) (psa->pba (l2p (zext64 la)))))))
      "Sectors in invalid blocks do not appear in L2P")
    (tagcond/desp 'blklist (list 'common 'blklist) (blklist-ptr-order usable erasable invalid used active)
      "Block list pointers are in certain orders")
    (tagcond/desp 'common #t (active-is-one-behind-usable active usable)
      "The active pointer is one behind the usable pointer")
    (tagcond/desp 'common #t (bveq pba_active (blk_list active))
      "The active data block is the first block in the active block queue")
    (tagcond/desp 'blklist #t (sufficient-blocks-for-write wcnt gcprog isa_active ipa_active usable invalid)
      "The data region does not run out of space")
    (tagcond/desp 'common #t (bvult usable (bv64 BLOCKS_DATA))
      "The usable pointer is less than the total number of data blocks")
    (tagcond/desp 'common #t (bvult erasable (bv64 BLOCKS_DATA))
      "The erasable pointer is less than the total number of data blocks")
    (tagcond/desp 'common #t (bvult invalid (bv64 BLOCKS_DATA))
      "The invalid pointer is less than the total number of data blocks")
    (tagcond/desp 'common #t (bvult used (bv64 BLOCKS_DATA))
      "The used pointer is less than the total number of data blocks")
    (tagcond/desp 'common #t (bvult active (bv64 BLOCKS_DATA))
      "The active pointer is less than the total number of data blocks")
    (tagcond/desp 'common #t (ri-all-committed-las-ule-nlas data pba_delta ipa_delta)
      "Committed delta pairs have LA less than or equal to the total number of LAs")
    (tagcond/desp 'common #t (ri-all-las-ule-nlas-delta-buf delta_buf)
      "Delta pairs in delta buffer have LA less than or equal to the total number of LAs")
    (tagcond/desp 'common #t (forall
      (list i)
      (=>
        (&&
          (bvuge i (zext64 ptr_delta_buf))
          (bvult i (bv64 N_DELTA_PAIR)))
        (bveq (delta_buf (bvadd i (bv64 OFFSET_LAS))) (bv32 N_LAS))))
      "Delta pairs in the right half of delta buffer are reserved")
    (tagcond/desp 'common #t (ri-ci-at-least-one-full-chkpt-is-committed data)
      "At least one full checkpoint is committed")
    (tagcond/desp 'common #t (ri-ci-both-full-chkpt-committed-record-are-synced synced)
      "Both full checkpoint commit flags are synchronized")
    (tagcond/desp 'common #t (ri-ci-full-chkpt-committed-record-implies-synced-l2p data synced)
      "A raised full checkpoint commit flag implies that the L2P table is synchronized")
    (tagcond/desp 'common #t (ri-ci-first-delta-chkpt-page-is-synced synced)
      "The first delta page is synchronized")
    (tagcond/desp 'common #t (ri-pba-ipa-delta-not-both-zero pba_delta ipa_delta)
      "The active delta block/page is not the first delta page")
    (tagcond/desp 'common #t (ri-cr-either-zero-or-one-before-pointer data pba_delta ipa_delta)
      "Delta pages before the active delta block/page are either committed or tentative")
    (tagcond/desp 'common #t (forall
      (list p)
      (synced (bv32 PBA_FIRST_FULL_COMMIT) p))
      "The first full checkpoint commit flag is synchronized")
    (tagcond/desp 'common #t (forall
      (list p)
      (synced (bv32 PBA_SECOND_FULL_COMMIT) p))
      "The second full checkpoint commit flag is synchronized")
    (tagcond/desp 'common #t (bvule isa_active (bv32 SECTORS_PER_PAGE))
      "The active data sector is less than or equal to the number of sectors per page")
    (tagcond/desp 'common #t (bvult ipa_active (bv32 PAGES_PER_BLOCK))
      "The active data page is less than the number of pages per block")
    (tagcond/desp 'common #t (bvule (bv32 PBA_DATA) pba_active)
      "The active data block is within the data region (lower bound)")
    (tagcond/desp 'common #t (bvult pba_active (bv32 (+ PBA_DATA BLOCKS_DATA)))
      "The active data block is within the data region (upper bound)")
    (tagcond/desp 'common #t (bvult isa_gc (bv32 SECTORS_PER_PAGE))
      "The victim sector is less than the number of sectors per page")
    (tagcond/desp 'common #t (bvult ipa_gc (bv32 PAGES_PER_BLOCK))
      "The victim page is less than the number of pages per block")
    (tagcond/desp 'common #t (bvule (bv32 PBA_DATA) pba_gc)
      "The victim block is within the data region (lower bound)")
    (tagcond/desp 'common #t (bvult pba_gc (bv32 (+ PBA_DATA BLOCKS_DATA)))
      "The victim block is within the data region (upper bound)")
    (tagcond/desp 'data #t (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range (zext64 la) l2p)))
      "L2P entries point to the data region")
    (tagcond/desp 'data #t (bvule (l2p (bv64 N_LAS)) (bv32 N_PAS))
      "The last L2P entry (a reserved slot) is less than or equal to the total number of PAs")
    (tagcond/desp 'data #t (forall
      (list pa)
      (=>
        (pa-valid? pa)
        (bvule (p2l (zext64 pa)) (bv32 N_LAS))))
      "P2L entries are less than or equal to the total number of LAs")
    (tagcond/desp 'data #t (bvule (p2l (bv64 N_PAS)) (bv32 N_LAS))
      "The last P2L entry (a reserved slot) is less than or equal to the total number of LAs")
    (tagcond/desp 'data #t (forall
      (list p)
      (=> (bvult p ipa_active) (! (erased pba_active p))))
      "Pages in the left half of the active block are programmed")
    (tagcond/desp 'data #t (forall
      (list p)
      (=> 
        (&&
          (bvule ipa_active p)
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (erased pba_active p)))
      "Pages in the right half of the active block are erased")
    (tagcond/desp 'data #t (forall
      (list i)
      (=>
        (&&
          (bvule (zext64 isa_active) i)
          (bvult i (bv64 SECTORS_PER_PAGE)))
        (bveq (lsas_merge i) (bv32 N_LAS))))
      "Unused merge buffers are tagged with the reserved LA")
    (tagcond/desp 'data #t (forall
      (list i)
      (=>
        (bvult i (zext64 isa_active))
        (bvult (lsas_merge i) (bv32 N_LAS))))
      "Each used merge buffer is tagged with a valid LA")
    (tagcond/desp 'data #t (=>
      (&&
        (! (bveq (lsas_merge (bv64 0)) (bv32 N_LAS)))
        (! (bveq (lsas_merge (bv64 0)) (lsas_merge (bv64 1)))))
      (&&
        (bveq pba_active (psa->pba (l2p (zext64 (lsas_merge (bv64 0))))))
        (bveq ipa_active (psa->ipa (l2p (zext64 (lsas_merge (bv64 0))))))
        (bveq (bv32 0) (psa->isa (l2p (zext64 (lsas_merge (bv64 0))))))))
      "The first used merge buffer will be written to the first sector of the active page unless it is overwritten by the second merge buffer")
    (tagcond/desp 'data #t (=>
      (! (bveq (lsas_merge (bv64 1)) (bv32 N_LAS)))
      (&&
        (bveq pba_active (psa->pba (l2p (zext64 (lsas_merge (bv64 1))))))
        (bveq ipa_active (psa->ipa (l2p (zext64 (lsas_merge (bv64 1))))))
        (bveq (bv32 1) (psa->isa (l2p (zext64 (lsas_merge (bv64 1))))))))
      "The second used merge buffer will be written to the second sector of the active page")
    (tagcond/desp 'gc #t (forall
      (list pa)
      (=>
        (pa-valid? pa)
        (=>
          (la-valid? (p2l (zext64 pa)))
          (bveq pa (l2p (zext64 (p2l (zext64 pa))))))))
      "Valid entries of P2L are pointed back by L2P")
    (tagcond/desp 'data #t (forall
      (list la)
      (=>
        (la-valid? la)
        (||
          (bveq la (lsas_merge (bv64 0)))
          (bveq la (lsas_merge (bv64 1)))
          (! (apply erased (psa->pba-ipa (l2p (zext64 la))))))))
      "L2P entries point to programmed pages except for those still in merge buffers")))

(define (abs-rel mach flash abst)
  (define-values
    (l2p p2l buf_merge buf_gc lsas_merge isa_active ipa_active pba_active
     isa_gc ipa_gc pba_gc lsa_gc gcprog enable_gc
     delta_buf ptr_delta_buf pba_delta ipa_delta ptr_full wcnt
     blk_list usable erasable invalid used active)
    (retrieve-machine mach))
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (define-values
    (volatile stable wcnt-abs
     ptr-buf map-ptr-buf ipa-delta pba-used map-pba-unstable map-ipa-unstable map-ptr-unstable
     pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable
     n-used-blks-abs isa-active ipa-active
     lsa-gc enable-gc n-gc-copied gcprog-abs)
    (retrieve-abstract abst))
  (define (disk l o)
    (define addr (psa->pba-ipa-isa64 (l2p (zext64 l))))
    (define pba (list-ref addr 0))
    (define ipa (list-ref addr 1))
    (define isa (list-ref addr 2))
    (cond
      [(bveq l (lsas_merge (bv64 1))) (buf_merge (bvadd (bv64 N_ENTRIES_PER_SECTOR) o))]
      [(bveq l (lsas_merge (bv64 0))) (buf_merge o)]
      [else (data pba ipa (bvadd (isa64->offset isa) o))]))
  (define committed-first?
    (bveq
      (data (bv32 PBA_FIRST_FULL_COMMIT) (bv32 0) (bv64 0))
      (bv32 0)))
  (define committed-second?
    (bveq
      (data (bv32 PBA_SECOND_FULL_COMMIT) (bv32 0) (bv64 0))
      (bv32 0)))
  (define (l2p-flash-first l)
    (define-values (b p o) (flat->hier l))
    (data (bvadd (bv32 PBA_FIRST_FULL) b) p o))
  (define (l2p-flash-second l)
    (define-values (b p o) (flat->hier l))
    (data (bvadd (bv32 PBA_SECOND_FULL) b) p o))
  (define (stable-l2p l)
    (cond
      [(! (bveq (map-ptr-stable l) (bv64 N_DELTA_PAIR))) (data (map-pba-stable l) (map-ipa-stable l) (offset-pas (map-ptr-stable l)))]
      [committed-first? (l2p-flash-first (zext64 l))]
      [committed-second? (l2p-flash-second (zext64 l))]
      ; should not reach this
      [else (bv32 0)]))
  (define-symbolic i i64)
  (define-symbolic la la2 i32)
  (define-symbolic offset i64)
  (list
    (tagcond/desp 'common #t (bveq gcprog gcprog-abs)
      "The GC counters are equal")
    (tagcond/desp 'common #t (bveq isa-active isa_active)
      "The active sectors are equal")
    (tagcond/desp 'common #t (bveq ipa-active ipa_active)
      "The active pages are equal")
    (tagcond/desp 'common (list 'common) (bveq lsa-gc lsa_gc)
      "The active sectors are equal")
    (tagcond/desp 'common #t (bveq enable-gc enable_gc)
      "The GC enabled flags are equal")
    (tagcond/desp 'common #t (bveq wcnt-abs wcnt)
      "The write counters are equal")
    (tagcond/desp 'common #t (bveq ptr-buf ptr_delta_buf)
      "The active delta pointers are equal")
    (tagcond/desp 'common #t (bveq ipa-delta ipa_delta)
      "The active delta pages are equal")
    (tagcond/desp 'common #t (bveq pba-used pba_delta)
      "The active delta blocks are equal")
    (tagcond/desp 'common #t (bveq n-gc-copied (bvadd (npgs->nsects ipa_gc) isa_gc))
      "The number of sectors copied by GC is consistent with the victim page/sector")
    (tagcond/desp 'common (list 'common 'blklist) (bveq
      n-used-blks-abs
      (n-used-blks used active))
      "The number of used block is consistent with the used and active block list pointer")
    (tagcond/desp 'common #t (bvule ipa-commit (bv32 PAGES_PER_BLOCK))
      "The page address of the last committed delta page is less than or equal to the number of pages per block")
    (tagcond/desp 'common #t (bvule pba-commit (bv32 BLOCKS_DELTA))
      "The block address of the last committed delta page points to the delta region")
    (tagcond/desp 'common #t (||
      (bvult pba-commit pba_delta)
      (&&
        (bveq pba-commit pba_delta)
        (bvule ipa-commit ipa_delta)))
      "The last committed page is behind or equal to the active delta page")
    (tagcond/desp 'common #t (ar-cr-all-uncommitted-after-commit data synced pba-commit ipa-commit)
      "Delta pages after the last committed page are uncommitted")
    (tagcond/desp 'common #t (all-synced-before-commit synced pba-commit ipa-commit)
      "Delta pages before the last committed page are synchronized")
    (tagcond/desp 'common #t (ar-cr-prev-committed-point-is-committed data pba-commit ipa-commit)
      "The last committed delta page is indeed committed")
    (tagcond/desp 'data-rel #t (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range la stable-l2p)))
      "Stable L2P entries point to the data region")
    (tagcond/desp 'data-rel #t (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-are-synced la stable-l2p synced)))
      "Stable L2P entries point to synchronized pages")
    (tagcond/desp 'blklist-rel #t (forall
      (list i la)
      (=>
        (&&
          (blklist-erasable? i erasable invalid)
          (la-valid? la))
        (! (bveq (blk_list i) (psa->pba (stable-l2p la))))))
      "Sectors in erasable blocks do not appear in stable L2P")
    (tagcond/desp 'data-rel #t (forall
      (list la)
      (=>
        (la-valid? la)
        (! (apply erased (psa->pba-ipa (stable-l2p la))))))
      "Stable L2P entries point to programmed pages")
    (tagcond/desp 'common #t (forall
      (list la offset)
      (=>
        (&&
          (la-valid? la)
          (offset-valid? offset))
        (bveq (volatile la offset) (disk la offset))))
      "The volatile sector array can be constructed by L2P and the data region")
    (tagcond/desp 'chkpt-b0 (list 'common 'chkpt-b0) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (la-in-delta-buf? la ptr_delta_buf delta_buf)
          (l2p-consistent-delta-buf la ptr_delta_buf delta_buf map-ptr-buf))))
      "If an LSA appears in the delta buffer, then the delta buffer index mapping maps the LSA to its last occurrence")
    (tagcond/desp 'chkpt-b1 (list 'common 'chkpt-b1) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (! (la-in-delta-buf? la ptr_delta_buf delta_buf))
          (la-not-in-delta-buf la map-ptr-buf))))
      "If an LSA does not appear in the delta buffer, then the delta buffer index mapping maps the LSA to the reserved value")
    (tagcond/desp 'chkpt-c0 (list 'common 'blklist 'blklist-rel 'chkpt-c0 'chkpt-b0 'chkpt-b1 'loop) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (la-in-delta? la data pba-used ipa-delta)
          (map-delta-consistent la data pba-used ipa-delta map-pba-unstable map-ipa-unstable map-ptr-unstable))))
      "If an LSA appears in the tentative delta region, then the tentative position mappings map the LSA to its last occurrence")
    (tagcond/desp 'chkpt-c1 (list 'common 'blklist 'blklist-rel 'chkpt-c1 'chkpt-b0 'chkpt-b1) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (! (la-in-delta? la data pba-used ipa-delta))
          (la-not-in-delta la map-pba-unstable map-ipa-unstable map-ptr-unstable))))
      "If an LSA does not appear in the tentative delta region, then the tentative index mapping maps the LSA to the reserved value")
    (tagcond/desp 'chkpt-d (list 'common 'blklist 'blklist-rel 'chkpt-d 'chkpt-c0 'chkpt-c1 'chkpt-b0 'chkpt-b1 'loop 'method) (forall
      (list la)
      (=>
        (la-valid? la)
        (map-l2p-consistent la l2p delta_buf pba-used lsas_merge pba_active ipa_active data map-ptr-buf map-pba-unstable map-ipa-unstable map-ptr-unstable)))
      "Starting with a committed full checkpoint and apply tentative delta checkpoints can obtain L2P")
    (tagcond/desp 'chkpt-e0 (list 'common 'blklist 'blklist-rel 'chkpt-e0 'chkpt-b0 'chkpt-b1 'chkpt-c0 'chkpt-c1 'loop) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (la-in-delta? la data pba-commit ipa-commit)
          (map-delta-consistent la data pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable))))
      "If an LSA appears in the committed delta region, then the committed position mappings map the LSA to its last occurrence")
    (tagcond/desp 'chkpt-e1 (list 'common 'blklist 'blklist-rel 'chkpt-e1 'chkpt-b0 'chkpt-b1 'chkpt-c0 'chkpt-c1) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (! (la-in-delta? la data pba-commit ipa-commit))
          (la-not-in-delta la map-pba-stable map-ipa-stable map-ptr-stable))))
      "If an LSA does not appear in the committed delta region, then the committed index mapping maps the LSA to the reserved value")
    (tagcond/desp 'chkpt-f #t (forall
      (list la offset)
      (=>
        (&&
          (la-valid? la)
          (offset-valid? offset))
        (map-stable-consistent la offset data map-pba-stable map-ipa-stable map-ptr-stable stable)))
      "Starting with a committed full checkpoint and apply committed delta checkpoints can obtain stable L2P; the stable sector array can be constructed by stable L2P and the data region")))

(define (crash-inv mach flash)
  ; crash inv should not use mach at all
  (define-values
    (erased synced data)
    (retrieve-flash flash))
  (list
    (tagcond/desp 'common #t (ri-ci-at-least-one-full-chkpt-is-committed data)
      "At least one full checkpoint is committed")
    (tagcond/desp 'common #t (ri-ci-both-full-chkpt-committed-record-are-synced synced)
      "Both full checkpoint commit flags are synchronized")
    (tagcond/desp 'common #t (ri-ci-full-chkpt-committed-record-implies-synced-l2p data synced)
      "A raised full checkpoint commit flag implies that the L2P table is synchronized")
    (tagcond/desp 'common #t (ri-ci-first-delta-chkpt-page-is-synced synced)
      "The first delta page is synchronized")
    (tagcond/desp 'common #t (||
      (ci-all-committed-las-ule-nlas data)
      (ci-committed-point-stop data))
      "Committed delta pairs have LA less than or equal to the total number of LAs unless the first delta page is uncommitted")))

(define (crash-rel mach flash abst)
  ; crash inv should not use mach at all
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

  (define committed-first?
    (bveq
      (data (bv32 PBA_FIRST_FULL_COMMIT) (bv32 0) (bv64 0))
      (bv32 0)))
  (define committed-second?
    (bveq
      (data (bv32 PBA_SECOND_FULL_COMMIT) (bv32 0) (bv64 0))
      (bv32 0)))
  (define (l2p-flash-first l)
    (define-values (b p o) (flat->hier l))
    (data (bvadd (bv32 PBA_FIRST_FULL) b) p o))
  (define (l2p-flash-second l)
    (define-values (b p o) (flat->hier l))
    (data (bvadd (bv32 PBA_SECOND_FULL) b) p o))
  (define (stable-l2p l)
    (cond
      [(! (bveq (map-ptr-stable l) (bv64 N_DELTA_PAIR))) (data (map-pba-stable l) (map-ipa-stable l) (offset-pas (map-ptr-stable l)))]
      [committed-first? (l2p-flash-first (zext64 l))]
      [committed-second? (l2p-flash-second (zext64 l))]
      ; should not reach this
      [else (bv32 0)]))

  (define-symbolic la la2 i32)
  (define-symbolic offset i64)
  (list
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (bvule ipa-commit (bv32 PAGES_PER_BLOCK))
      "The page address of the last committed delta page is less than or equal to the number of pages per block")
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (bvult pba-commit (bv32 BLOCKS_DELTA))
      "The block address of the last committed delta page points to the delta region")
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (||
        (ar-cr-all-uncommitted-after-commit data synced pba-commit ipa-commit)
        (cr-committed-point-stop data pba-commit ipa-commit))
      "Delta pages after the last committed page are uncommitted unless the first delta page is uncommitted")
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (all-synced-before-commit synced pba-commit ipa-commit)
      "Delta pages before the last committed page are synchronized")
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (ar-cr-prev-committed-point-is-committed data pba-commit ipa-commit)
      "The last committed delta page is indeed committed")
    (tagcond/desp 'common (list 'common 'blklist 'blklist-rel 'loop 'method)
      (ri-cr-either-zero-or-one-before-pointer data pba-commit ipa-commit)
      "Delta pages before the active delta block/page are either committed or tentative")
    (tagcond/desp 'common #t (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-within-data-psa-range la stable-l2p)))
      "Stable L2P entries point to the data region")
    (tagcond/desp 'common #t (forall
      (list la)
      (=>
        (la-valid? la)
        (mapped-entries-are-synced la stable-l2p synced)))
      "Stable L2P entries point to synchronized pages")
    (tagcond/desp 'common #t (forall
      (list la)
      (=>
        (la-valid? la)
        (! (apply erased (psa->pba-ipa (stable-l2p la))))))
      "Stable L2P entries point to programmed pages")
    (tagcond/desp 'chkpt-e0 (list 'common 'blklist 'blklist-rel 'chkpt-e0 'chkpt-b0 'chkpt-b1 'chkpt-c0 'chkpt-c1 'loop 'method) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (la-in-delta? la data pba-commit ipa-commit)
          (map-delta-consistent la data pba-commit ipa-commit map-pba-stable map-ipa-stable map-ptr-stable))))
      "If an LSA appears in the committed delta region, then the committed position mappings map the LSA to its last occurrence")
    (tagcond/desp 'chkpt-e1 (list 'common 'blklist 'blklist-rel 'chkpt-e1 'chkpt-b0 'chkpt-b1 'chkpt-c0 'chkpt-c1) (forall
      (list la)
      (=>
        (la-valid? la)
        (=>
          (! (la-in-delta? la data pba-commit ipa-commit))
          (la-not-in-delta la map-pba-stable map-ipa-stable map-ptr-stable))))
      "If an LSA does not appear in the committed delta region, then the committed index mapping maps the LSA to the reserved value")
    (tagcond/desp 'chkpt (list 'common 'blklist 'blklist-rel 'chkpt 'data 'data-rel 'chkpt-b0 'chkpt-b1 'chkpt-c0 'chkpt-c1 'chkpt-d 'chkpt-e0 'chkpt-e1 'chkpt-f 'loop 'method) (forall
      (list la offset)
      (=>
        (&&
          (la-valid? la)
          (offset-valid? offset))
        (map-stable-consistent la offset data map-pba-stable map-ipa-stable map-ptr-stable stable)))
      "Starting with a committed full checkpoint and apply committed delta checkpoints can obtain stable L2P; the stable sector array can be constructed by stable L2P and the data region")))
