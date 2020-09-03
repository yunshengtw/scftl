#lang rosette

(require serval/lib/core
         "./lib/flash.rkt"
         "./misc.rkt"
         "./const.rkt")

(provide (all-defined-out))

(define (la-valid? la)
  (bvult la (bv32 N_LAS)))

(define (pa-valid? pa)
  (bvult pa (bv32 N_PAS)))

(define (offset-valid? offset)
  (bvult offset (bv64 N_ENTRIES_PER_SECTOR)))

(define (diff-ptr-valid? i)
  (bvult i (bv64 N_DELTA_PAIR)))

(define (blklist-ptr-valid? i)
  (bvult i (bv64 BLOCKS_DATA)))

(define (blklist-usable? i usable erasable)
  (blklist-generic i usable erasable))

(define (blklist-used? i used active)
  (blklist-generic i used active))

(define (blklist-erasable? i erasable invalid)
  (blklist-generic i erasable invalid))

(define (blklist-invalid? i invalid used)
  (blklist-generic i invalid used))

(define (blklist-generic i start end)
  (cond
    [(bvule start end)
     (&&
      (bvule start i)
      (bvult i end))]
    [else
     (||
      (&&
        (bvule start i)
        (bvult i (bv64 BLOCKS_DATA)))
      (bvult i end))]))

(define (la-in-delta-buf? la n delta-buf)
  (define-symbolic i i64)
  (define n-extended (zext64 n))
  (exists
    (list i)
    (&&
      (bvult i n-extended)
      (bveq (delta-buf (bvadd i (bv64 OFFSET_LAS))) la))))

(define (l2p-consistent-delta-buf la n delta-buf map-ptr-buf)
  (define-symbolic j i64)
  (define la-extended (zext64 la))
  (define n-extended (zext64 n))
  (&&
    (bvult (map-ptr-buf la) n-extended)
    (bveq (delta-buf (bvadd (map-ptr-buf la) (bv64 OFFSET_LAS))) la)
    (forall
      (list j)
      (=>
        (&& (bvult (map-ptr-buf la) j) (bvult j n-extended))
        (! (bveq (delta-buf (bvadd j (bv64 OFFSET_LAS))) la))))))

(define (la-not-in-delta-buf la map-ptr-buf)
  (bveq (map-ptr-buf la) (bv64 N_DELTA_PAIR)))

(define (la-in-delta? la delta pba ipa)
  (define-symbolic i i64)
  (define-symbolic p b i32)
  (exists
    (list i p b)
    (&&
      (bvult i (bv64 N_DELTA_PAIR))
      (||
        (&&
          (bvult p (bv32 PAGES_PER_BLOCK))
          (bvult b pba))
        (&&
          (bvult p ipa)
          (bveq b pba)))
      (bveq (delta b p (bvadd i (bv64 OFFSET_LAS))) la))))

(define (map-delta-consistent la delta pba ipa map-pba map-ipa map-ptr)
  (define-symbolic j i64)
  (define-symbolic q c i32)
  (define la-extended (zext64 la))
  (&&
    (bvult (map-ptr la) (bv64 N_DELTA_PAIR))
    (||
      (&&
        (bvult (map-ipa la) (bv32 PAGES_PER_BLOCK))
        (bvult (map-pba la) pba))
      (&&
        (bvult (map-ipa la) ipa)
        (bveq (map-pba la) pba)))
    (bveq (delta (map-pba la) (map-ipa la) (bvadd (map-ptr la) (bv64 OFFSET_LAS))) la)
    (forall
      (list j q c)
      (=>
        (&&
          (bvult j (bv64 N_DELTA_PAIR))
          (bvult q (bv32 PAGES_PER_BLOCK))
          (||
            (bvult (map-pba la) c)
            (&&
              (bveq (map-pba la) c)
              (bvult (map-ipa la) q))
            (&&
              (bveq (map-pba la) c)
              (bveq (map-ipa la) q)
              (bvult (map-ptr la) j)))
          (||
            (bvult c pba)
            (&&
              (bveq c pba)
              (bvult q ipa))))
        (! (bveq (delta c q (bvadd j (bv64 OFFSET_LAS))) la))))))

(define (la-not-in-delta la map-pba map-ipa map-ptr)
  (bveq (map-ptr la) (bv64 N_DELTA_PAIR)))

(define (map-l2p-consistent
  la l2p delta_buf pba_delta lsas_merge pba_active ipa_active data
  map-ptr-buf
  map-pba-unstable
  map-ipa-unstable
  map-ptr-unstable)
  (define la-extended (zext64 la))
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
  (define (unstable l)
    (cond
      [(! (bveq (map-ptr-buf l) (bv64 N_DELTA_PAIR))) (delta_buf (offset-pas (map-ptr-buf l)))]
      [(! (bveq (map-ptr-unstable l) (bv64 N_DELTA_PAIR))) (data (map-pba-unstable l) (map-ipa-unstable l) (offset-pas (map-ptr-unstable l)))]
      [committed-first? (l2p-flash-first (zext64 l))]
      [committed-second? (l2p-flash-second (zext64 l))]
      ; should not reach this
      [else (bv32 0)]))
  ; maybe go back to simply use l2p
  (define (l2p-with-merge-buf l)
    (cond
      [(bveq l (lsas_merge (bv64 1))) (pba-ipa-isa->psa pba_active ipa_active (bv32 1))]
      [(bveq l (lsas_merge (bv64 0))) (pba-ipa-isa->psa pba_active ipa_active (bv32 0))]
      [else (l2p (zext64 l))]))
  (bveq
    (l2p la-extended) (unstable la)))
    ; (l2p-with-merge-buf la) (unstable la)))

(define (map-stable-consistent
  la offset data
  map-pba-stable
  map-ipa-stable
  map-ptr-stable
  stable)
  (define la-extended (zext64 la))
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
  (define (stable-chkpt l)
    (cond
      [(! (bveq (map-ptr-stable l) (bv64 N_DELTA_PAIR))) (data (map-pba-stable l) (map-ipa-stable l) (offset-pas (map-ptr-stable l)))]
      [committed-first? (l2p-flash-first (zext64 l))]
      [committed-second? (l2p-flash-second (zext64 l))]
      ; should not reach this
      [else (bv32 0)]))
  (define (disk-stable l o)
    (define addr (psa->pba-ipa-isa64 (stable-chkpt l)))
    (define pba (list-ref addr 0))
    (define ipa (list-ref addr 1))
    (define isa (list-ref addr 2))
    (data pba ipa (bvadd (isa64->offset isa) o)))
  (bveq
    (disk-stable la offset) (stable la offset)))

(define (map-partial-l2p-consistent
  la data l2p
  map-pba-stable map-ipa-stable map-ptr-stable)
  (bveq
    (l2p (zext64 la))
    (data (map-pba-stable la) (map-ipa-stable la) (offset-pas (map-ptr-stable la)))))

(define (l2p-l2p0-consistent la l2p l2p0)
  (bveq
    (l2p (zext64 la))
    (l2p0 (zext64 la))))

(define (ar-cr-all-uncommitted-after-commit delta synced pba-commit ipa-commit)
  (define-symbolic b p i32)
  (forall
    (list b p)
    (=>
      (||
        (&&
          (bvult pba-commit b)
          (bvult b (bv32 BLOCKS_DELTA))
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (&&
          (bveq b pba-commit)
          (bvule ipa-commit p)
          (bvult p (bv32 PAGES_PER_BLOCK))))
      (&&
        (! (bveq (delta b p (bv64 0)) (bv32 0)))
        (synced b p)))))
        ; (=>
        ;   (! (synced b p))
        ;   (marked b p))))))

(define (ri-ci-first-delta-chkpt-page-is-synced synced)
  (synced (bv32 PBA_DELTA_START) (bv32 0)))

(define (ar-cr-prev-committed-point-is-committed delta pba-commit ipa-commit)
  (=>
    (!
      (&&
        (bveq pba-commit (bv32 0))
        (bveq ipa-commit (bv32 0))))
    (&&
      (=>
        (bveq ipa-commit (bv32 0))
        (bveq (delta (bvsub pba-commit (bv32 1)) (bvsub (bv32 PAGES_PER_BLOCK) (bv32 1)) (bv64 0)) (bv32 0)))
      (=>
        (! (bveq ipa-commit (bv32 0)))
        (bveq (delta pba-commit (bvsub ipa-commit (bv32 1)) (bv64 0)) (bv32 0))))))

(define (ri-cr-either-zero-or-one-before-pointer delta pba ipa)
  (define-symbolic b p i32)
  (forall
    (list b p)
    (=>
      (||
        (&&
          (bvult b pba)
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (&&
          (bveq b pba)
          (bvult p ipa)))
      (||
        (bveq (delta b p (bv64 0)) (bv32 0))
        (bveq (delta b p (bv64 0)) (bv32 1))))))

(define (ri-pba-ipa-delta-not-both-zero pba ipa)
  (||
    (! (bveq pba (bv32 0)))
    (! (bveq ipa (bv32 0)))))

(define (cr-committed-point-stop delta pba-commit ipa-commit)
  (&&
    (bveq pba-commit (bv32 0))
    (bveq ipa-commit (bv32 0))
    (! (bveq (delta pba-commit ipa-commit (bv64 0)) (bv32 0)))
    (! (bveq (delta pba-commit ipa-commit (bv64 0)) (bv32 1)))))

(define (ri-all-las-ule-nlas-delta-buf buf)
  (define-symbolic i i64)
  (forall
    (list i)
    (=>
      (bvult i (bv64 N_DELTA_PAIR))
      (bvule (buf (offset-las i)) (bv32 N_LAS)))))

(define (ri-all-committed-las-ule-nlas delta pba ipa)
  (define-symbolic b p i32)
  (define-symbolic i i64)
  (forall
    (list b p i)
    (=>
      (&&
        (bvult i (bv64 N_DELTA_PAIR))
        (||
          (&&
            (bvult b pba)
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (&&
            (bveq b pba)
            (bvult p ipa))))
      (bvule (delta b p (offset-las i)) (bv32 N_LAS)))))

(define (ci-all-committed-las-ule-nlas delta)
  (define-symbolic b p c q i32)
  (define-symbolic i i64)
  (forall
    (list b p c q i)
    (=>
      (&&
        (bvult b (bv32 BLOCKS_DELTA))
        (bvult p (bv32 PAGES_PER_BLOCK))
        (bvult i (bv64 N_DELTA_PAIR))
        (bveq (delta b p (bv64 0)) (bv32 0))
        (||
          (&&
            (bvult c b)
            (bvult q (bv32 PAGES_PER_BLOCK)))
          (&&
            (bveq c b)
            (bvule q p))))
      (bvule (delta c q (offset-las i)) (bv32 N_LAS)))))

(define (ci-committed-point-stop delta)
  (&&
    (! (bveq (delta (bv32 0) (bv32 0) (bv64 0)) (bv32 0)))
    (! (bveq (delta (bv32 0) (bv32 0) (bv64 0)) (bv32 1)))))

(define (ri-ci-at-least-one-full-chkpt-is-committed delta)
  (||
    (bveq (delta (bv32 PBA_FIRST_FULL_COMMIT) (bv32 0) (bv64 0)) (bv32 0))
    (bveq (delta (bv32 PBA_SECOND_FULL_COMMIT) (bv32 0) (bv64 0)) (bv32 0))))

(define (ri-ci-both-full-chkpt-committed-record-are-synced synced)
  (&&
    (synced (bv32 PBA_FIRST_FULL_COMMIT) (bv32 0))
    (synced (bv32 PBA_SECOND_FULL_COMMIT) (bv32 0))))

(define (ri-ci-full-chkpt-committed-record-implies-synced-l2p delta synced)
  (define-symbolic b p i32)
  (&&
    (=>
      (bveq (delta (bv32 PBA_FIRST_FULL_COMMIT) (bv32 0) (bv64 0)) (bv32 0))
      (forall
        (list b p)
        (=>
          (&&
            (bvule (bv32 PBA_FIRST_FULL) b)
            (bvult b (bv32 PBA_FIRST_FULL_COMMIT))
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (synced b p))))
    (=>
      (bveq (delta (bv32 PBA_SECOND_FULL_COMMIT) (bv32 0) (bv64 0)) (bv32 0))
      (forall
        (list b p)
        (=>
          (&&
            (bvule (bv32 PBA_SECOND_FULL) b)
            (bvult b (bv32 PBA_SECOND_FULL_COMMIT))
            (bvult p (bv32 PAGES_PER_BLOCK)))
          (synced b p))))))

(define (all-synced-before-commit synced pba-commit ipa-commit)
  (define-symbolic b p i32)
  (forall
    (list b p)
    (=>
      (||
        (&&
          (bvult b pba-commit)
          (bvult p (bv32 PAGES_PER_BLOCK)))
        (&&
          (bveq b pba-commit)
          (bvult p ipa-commit)))
      (synced b p))))
          
(define (mapped-entries-within-data-psa-range la tbl)
  (&&
    (bvule (bv32 (* PBA_DATA PAGES_PER_BLOCK SECTORS_PER_PAGE)) (tbl la))
    (bvule (tbl la) (bv32 N_PAS))))

(define (mapped-entries-are-synced la tbl synced)
  (define addr (psa->pba-ipa (tbl la)))
  (apply synced addr))

(define (active-is-one-behind-usable active usable)
  (||
    (&&
      (bveq active (bv64 (- BLOCKS_DATA 1)))
      (bveq usable (bv64 0)))
    (bveq (bvadd active (bv64 1)) usable)))

(define (sufficient-blocks-for-write wcnt gcprog isa_active ipa_active usable invalid)
  (bvugt
    (bvadd wcnt gcprog (n-avail-sects isa_active ipa_active usable invalid))
    (bv32 (+ MAX_WCNT MAX_GCPROG (* PAGES_PER_BLOCK SECTORS_PER_PAGE)))))

(define (sufficient-ready-blocks usable used)
  (bvuge
    (n-ready-blks usable used)
    (bv64 36)))

(define (blklist-ptr-order usable erasable invalid used active)
  (||
    ; usable -> erasable -> invalid -> used -> active
    (&&
      (bvule usable erasable)
      (bvule erasable invalid)
      (bvule invalid used)
      (bvule used active))
    ; active -> usable -> erasable -> invalid -> used
    (&&
      (bvule active usable)
      (bvule usable erasable)
      (bvule erasable invalid)
      (bvule invalid used))
    ; used -> active -> usable -> erasable -> invalid
    (&&
      (bvule used active)
      (bvule active usable)
      (bvule usable erasable)
      (bvule erasable invalid))
    ; invalid -> used -> active -> usable -> erasable
    (&&
      (bvule invalid used)
      (bvule used active)
      (bvule active usable)
      (bvule usable erasable))
    ; erasable -> invalid -> used -> active -> usable
    (&&
      (bvule erasable invalid)
      (bvule invalid used)
      (bvule used active)
      (bvule active usable))))
