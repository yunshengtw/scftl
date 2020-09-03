#include <stdint.h>
#include <stddef.h>
//#include <stdio.h>
//#include <assert.h>

/* Independent parameters */
#define BLOCKS_DELTA    64
#define BLOCKS_FULL     1
#define BLOCKS_DATA     1536
#define PAGES_PER_BLOCK 512
#define PAGE_SIZE       8192    /* Currently, a page must contain exactly two sectors */
#define SECTOR_SIZE     4096
#define MAX_WCNT        2048
#define THRESHOLD_GC    1400

/* Dependent parameters */
#define BLOCKS_TOTAL            (BLOCKS_DELTA + (2 * (BLOCKS_FULL + 1)) + BLOCKS_DATA)
#define SECTORS_PER_PAGE        (PAGE_SIZE / SECTOR_SIZE)
#define SECTORS_PER_BLOCK       (PAGES_PER_BLOCK * SECTORS_PER_PAGE)
#define N_ENTRIES_PER_PAGE      (PAGE_SIZE / 4)     /* An entry is a U32 */
#define N_ENTRIES_PER_SECTOR    (SECTOR_SIZE / 4)
#define N_LAS                   (BLOCKS_FULL * PAGES_PER_BLOCK * N_ENTRIES_PER_PAGE - 1)
#define N_PAS                   (BLOCKS_TOTAL * PAGES_PER_BLOCK * SECTORS_PER_PAGE)
#define N_DELTA_PAIR            (N_ENTRIES_PER_PAGE / 2 - 1)
#define THRESHOLD_DELTA_WB      (BLOCKS_DELTA - (MAX_WCNT / (N_DELTA_PAIR * PAGES_PER_BLOCK) + 2))
#define MAX_GCPROG              (MAX_WCNT * 16)

/* Block layout */
#define PBA_DELTA               0
#define PBA_FIRST_FULL          BLOCKS_DELTA
#define PBA_FIRST_FULL_COMMIT   (PBA_FIRST_FULL + BLOCKS_FULL)
#define PBA_SECOND_FULL         (PBA_FIRST_FULL_COMMIT + 1)
#define PBA_SECOND_FULL_COMMIT  (PBA_SECOND_FULL + BLOCKS_FULL)
#define PBA_DATA                (PBA_SECOND_FULL_COMMIT + 1)

/* Offset for delta chkpt page */
#define OFFSET_COMMIT   0
#define OFFSET_LAS      2
#define OFFSET_PAS      (OFFSET_LAS + N_DELTA_PAIR)

/* Flags and other constants */
#define FLAG_DELTA_COMMITTED 0
#define FLAG_DELTA_TENTATIVE 1
#define LSA_INVALID N_LAS
#define PSA_INVALID N_PAS

#define BLK_LIST_NEXT(ptr) ((ptr) == BLOCKS_DATA - 1 ? 0 : (ptr) + 1)
#define PSA_TO_PBA(psa) ((psa) / SECTORS_PER_BLOCK)
#define PSA_TO_IPA(psa) (((psa) & (SECTORS_PER_BLOCK - 1)) / SECTORS_PER_PAGE)
#define PSA_TO_ISA(psa) ((psa) & (SECTORS_PER_PAGE - 1))

/* Active data pointers and merge buffer */
uint32_t isa_active, ipa_active, pba_active;
uint32_t lsas_merge[SECTORS_PER_PAGE];
uint32_t buf_merge[N_ENTRIES_PER_PAGE];

/* Checkpoint */
uint32_t delta_buf[N_ENTRIES_PER_PAGE];
uint32_t ptr_delta_buf;
uint32_t pba_delta, ipa_delta;
uint32_t ptr_full;
uint32_t buf_commit[N_ENTRIES_PER_PAGE];

/* Non-observable variables */
uint32_t blkid, pgid, sectid;
uint64_t idx;
uint32_t buf_tmp[N_ENTRIES_PER_PAGE];
uint32_t pba_committed;
uint32_t ipa_committed;
uint8_t is_used[BLOCKS_DATA + 1];
uint32_t buf_read[N_ENTRIES_PER_PAGE];

/* Block list (queues) */
/**
 * [usable, erasable): usable blocks
 * [erasable, invalid): erasable blocks
 * [invalid, used): invalid blocks
 * [used, active): used block
 * [active, usable): active blocks
 */
uint64_t usable, erasable, invalid, used, active;
uint32_t blk_list[BLOCKS_DATA];

/* GC */
uint32_t isa_gc, ipa_gc, pba_gc;
uint32_t lsa_gc;
uint32_t buf_gc[N_ENTRIES_PER_PAGE];
uint32_t gcprog;
uint32_t enable_gc;
uint16_t vcnts[BLOCKS_TOTAL + 1];
uint64_t idx_victim;
uint16_t min_vcnt;

/* Global state */
uint32_t l2p[N_LAS + 1];
uint32_t p2l[N_PAS + 1];
uint32_t wcnt;

/* For validation */
uint32_t failed;
uint8_t pa_used[N_PAS + 1];

/* For verification */
uint32_t host_data[N_ENTRIES_PER_SECTOR];

/* Flash API start */
void flash_read(uint32_t blkid, uint32_t pgid, uint32_t *data);
void flash_read_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data);
void flash_program(uint32_t blkid, uint32_t pgid, uint32_t *data, uint32_t sync);
void flash_program_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data);
void flash_erase(uint32_t blkid, uint32_t sync);
void flash_erase_bulk(uint32_t blkid, uint32_t nblks);
void flash_sync(void);
/* Flash API end */

/* Memeory operation start */
__attribute__((noinline))
void *memcpy32(uint32_t *dst, uint32_t *src, size_t len)
{
    size_t i;

    for (i = 0; i < len; ++i)
        dst[i] = src[i];

    return dst;
}

__attribute__((noinline))
uint32_t *memset32(uint32_t *p, uint32_t v, size_t len)
{
    size_t i;

    for (i = 0; i < len; ++i)
        p[i] = v;

    return p;
}

__attribute__((noinline))
void *memset(void *p, int c, size_t len)
{
    char *s = p;
    size_t i;

    for (i = 0; i < len; ++i)
        s[i] = c;

    return p;
}
/* Memeory operation end */

__attribute__((noinline))
void check_sufficient_avail_blocks(void)
{
    if (erasable <= BLOCKS_DATA - 36)
        failed = 0;
    else
        failed = 1;
}

__attribute__((noinline))
void check_sufficient_ready_blocks(void)
{
    uint32_t n_ready_blks = 
        (usable <= used) ? (used - usable) : (used + BLOCKS_DATA - usable);
    if (n_ready_blks >= 36)
        failed = 0;
    else
        failed = 1;
}

__attribute__((noinline))
void check_l2p_injective_body(void)
{
    uint32_t pa = l2p[sectid];
    if (pa != N_PAS && pa_used[pa] == 1)
        failed = 1;
    pa_used[pa] = 1;
    sectid++;
}

__attribute__((noinline))
void check_l2p_injective_loop(void)
{
    while (sectid != N_LAS)
        check_l2p_injective_body();
}

__attribute__((noinline))
void check_l2p_injective(void)
{
    sectid = 0;
    failed = 0;
    memset(pa_used, 0, N_PAS + 1);
    check_l2p_injective_loop();
    /*
    if (failed)
        printf("L2P NOT injective\n");
    else
        printf("L2P injective\n");
    assert(failed == 0);
    */
}

/* Block management start */
void choose_free_block(void)
{
    pba_active = blk_list[usable];
    active = usable;
    usable = BLK_LIST_NEXT(usable);
}

void make_all_invalid_blocks_erasable(void)
{
    invalid = used;
}

void make_one_erasable_block_free(void)
{
    flash_erase(blk_list[erasable], 0);
    erasable = BLK_LIST_NEXT(erasable);
}

int free_blklist_empty(void)
{
    return (usable == erasable);
}

int erasable_blklist_empty(void)
{
    return (erasable == invalid);
}

__attribute__((noinline))
void categorize_used_and_erasable_blocks_body(void)
{
    if (is_used[idx]) {
        blk_list[idx] = blk_list[erasable];
        blk_list[erasable] = blkid;
        erasable++;
    } else {
        blk_list[idx] = blkid;
    }

    idx++;
    blkid++;
}

__attribute__((noinline))
void categorize_used_and_erasable_blocks_loop(void)
{
    while (idx != BLOCKS_DATA)
        categorize_used_and_erasable_blocks_body();
}

void categorize_used_and_erasable_blocks(void)
{
    idx = 0;
    blkid = PBA_DATA;
    categorize_used_and_erasable_blocks_loop();
}

__attribute__((noinline))
void identify_used_blocks_body(void)
{
    uint32_t pba = PSA_TO_PBA(l2p[sectid]);
    is_used[pba - PBA_DATA] = 1;

    sectid++;
}

__attribute__((noinline))
void identify_used_blocks_loop(void)
{
    while (sectid != N_LAS)
        identify_used_blocks_body();
}

void identify_used_blocks(void)
{
    sectid = 0;
    identify_used_blocks_loop();
}

void reconstruct_block_list(void)
{
    erasable = 0;
    invalid = 0;
    used = 0;
    memset(is_used, 0, sizeof(is_used));
    identify_used_blocks();
    categorize_used_and_erasable_blocks();
    usable = erasable;
}
/* Block management end */

/* Merge buffer start */
void invalidate_merge_buffer(void)
{
    for (uint32_t i = 0; i < SECTORS_PER_PAGE; i++) {
        lsas_merge[i] = LSA_INVALID;
    }
    isa_active = 0;
}

void reset_data_pointer(void)
{
    ipa_active = 0;
    choose_free_block();
}

void reset_gc_pointer(void)
{
    enable_gc = 0;
    ipa_gc = 0;
    isa_gc = 0;
    pba_gc = PBA_DATA;
    lsa_gc = N_LAS;
}

__attribute__((noinline))
void persist_merge_buffer(void)
{
    /* persist merge buffer @ (pba_active, ipa_active) */
    flash_program(pba_active, ipa_active, buf_merge, 0);
    invalidate_merge_buffer();
    ipa_active++;

    if (ipa_active == PAGES_PER_BLOCK) {
        ipa_active = 0;
        choose_free_block();
        /* pba_active is a usable block */
    }
}

int merge_buf_full(void)
{
    return (isa_active == SECTORS_PER_PAGE);
}

int merge_buf_empty(void)
{
    return (isa_active == 0);
}

/* Inlining this function seems to break Serval */
__attribute__((noinline))
void copy_data_to_merge_buf(uint32_t lsa, uint32_t *data)
{
    memcpy32(&buf_merge[isa_active * N_ENTRIES_PER_SECTOR], data, N_ENTRIES_PER_SECTOR);

    lsas_merge[isa_active] = lsa;
    isa_active++;
}
/* Merge buffer end */

/* GC start */
/* Optimization not used */
int gc_page_valid(void)
{
    int should_relocate = 0;
    uint32_t psa_gc = (pba_gc * PAGES_PER_BLOCK + ipa_gc) * SECTORS_PER_PAGE;
    for (uint32_t i = 0; i < SECTORS_PER_PAGE; i++)
        should_relocate |= (p2l[psa_gc + i] != LSA_INVALID);

    return should_relocate;
}
/* GC end */

/* Recovery start */
void reset_committed_point(void)
{
    pba_committed = 0;
    ipa_committed = 0;
}

__attribute__((noinline))
void find_last_committed_delta_chkpt_body(void)
{
    flash_read(blkid, pgid, buf_tmp);
    if (buf_tmp[0] == 0) {
        pba_committed = blkid;
        ipa_committed = pgid + 1;
    }

    pgid++;
    if (pgid == PAGES_PER_BLOCK) {
        pgid = 0;
        blkid++;
    }
}
__attribute__((noinline))
void find_last_committed_delta_chkpt_loop(void)
{
    while (blkid != BLOCKS_DELTA)
        find_last_committed_delta_chkpt_body();
}

void find_last_committed_delta_chkpt(void)
{
    reset_committed_point();
    blkid = 0;
    pgid = 0;
    find_last_committed_delta_chkpt_loop();
}

int first_delta_page_erased(void)
{
    flash_read(PBA_DELTA, 0, buf_tmp);
    return (buf_tmp[0] != 0 && buf_tmp[0] != 1);
}

__attribute__((noinline))
void apply_delta_chkpt_body(void)
{
    if (!idx)
        flash_read(blkid, pgid, buf_tmp);
    
    if (!(blkid > pba_committed || (blkid == pba_committed && pgid >= ipa_committed))) {
        uint32_t la = buf_tmp[idx + OFFSET_LAS];
        uint32_t pa = buf_tmp[idx + OFFSET_PAS];
        l2p[la] = pa;
    }

    idx++;
    if (idx == N_DELTA_PAIR) {
        idx = 0;
        pgid++;
    }
    if (pgid == PAGES_PER_BLOCK) {
        pgid = 0;
        blkid++;
    }
}

__attribute__((noinline))
void apply_delta_chkpt_loop(void)
{
    while (blkid != BLOCKS_DELTA)
        apply_delta_chkpt_body();
}

void apply_delta_chkpt(void)
{
    blkid = 0;
    pgid = 0;
    idx = 0;
    apply_delta_chkpt_loop();
}

__attribute__((noinline))
void invalidate_p2l_body(void)
{
    p2l[idx] = N_LAS;

    idx++;
}

__attribute__((noinline))
void invalidate_p2l_loop(void)
{
    while (idx != (N_PAS + 1))
        invalidate_p2l_body();
}

void invalidate_p2l(void)
{
    idx = 0;
    invalidate_p2l_loop();
}

__attribute__((noinline))
void reset_vcnts_body(void)
{
    vcnts[idx] = 0;

    idx++;
}

__attribute__((noinline))
void reset_vcnts_loop(void)
{
    while (idx != BLOCKS_TOTAL)
        reset_vcnts_body();
}

void reset_vcnts(void)
{
    idx = 0;
    reset_vcnts_loop();
}

__attribute__((noinline))
void count_valid_sectors_body(void)
{
    uint32_t pba = PSA_TO_PBA(l2p[sectid]);
    vcnts[pba]++;

    sectid++;
}

__attribute__((noinline))
void count_valid_sectors_loop(void)
{
    while (sectid != N_LAS)
        count_valid_sectors_body();
}

void count_valid_sectors(void)
{
    sectid = 0;
    count_valid_sectors_loop();
}

__attribute__((noinline))
void remap_valid_sectors_body(void)
{
    uint32_t pa = l2p[idx];
    if (pa < N_PAS)
        p2l[pa] = idx;

    idx++;
}

__attribute__((noinline))
void remap_valid_sectors_loop(void)
{
    while (idx != N_LAS)
        remap_valid_sectors_body();
}

void remap_valid_sectors(void)
{
    idx = 0;
    remap_valid_sectors_loop();
}
/* Recovery end */

/* Delta chkpt start */
__attribute__((noinline))
void invalidate_delta_buf_body(void)
{
    delta_buf[idx] = N_LAS;

    idx++;
}

__attribute__((noinline))
void invalidate_delta_buf_loop(void)
{
    while (idx != OFFSET_LAS + N_DELTA_PAIR)
        invalidate_delta_buf_body();
}

void invalidate_delta_buf(void)
{
    idx = OFFSET_LAS;
    invalidate_delta_buf_loop();
}

void append_delta_pair(uint32_t la, uint32_t pa)
{
    delta_buf[ptr_delta_buf + OFFSET_LAS] = la;
    delta_buf[ptr_delta_buf + OFFSET_PAS] = pa;
    ptr_delta_buf++;
}

__attribute__((noinline))
void create_one_delta_chkpt(uint32_t flag)
{
    if (ipa_delta == PAGES_PER_BLOCK) {
        ipa_delta = 0;
        pba_delta++;
    }
    delta_buf[OFFSET_COMMIT] = flag;
    flash_program(pba_delta, ipa_delta, delta_buf, 1);
    ipa_delta++;
}

void delete_all_delta_chkpts(void)
{
    flash_erase(PBA_DELTA, 1);
    flash_erase_bulk(PBA_DELTA + 1, BLOCKS_DELTA - 1);
    flash_sync();
    delta_buf[OFFSET_COMMIT] = 0;
    flash_program(PBA_DELTA, 0, delta_buf, 1);
    ipa_delta = 1;
    pba_delta = 0;
}

void reset_delta_buf(void)
{
    ptr_delta_buf = 0;
    invalidate_delta_buf();
}

int delta_chkpt_region_almost_full(void)
{
    return (pba_delta >= THRESHOLD_DELTA_WB);
}

int delta_chkpt_buf_full(void)
{
    return (ptr_delta_buf == N_DELTA_PAIR);
}
/* Delta chkpt end */

/* Full chkpt start */
void create_full_chkpt(void)
{
    uint32_t pba_full;
    pba_full = (ptr_full == 0 ? PBA_FIRST_FULL : PBA_SECOND_FULL);
    flash_program_bulk(pba_full, BLOCKS_FULL, l2p);
    flash_sync();
    buf_commit[0] = 0;
    flash_program(pba_full + BLOCKS_FULL, 0, buf_commit, 1);
}

void delete_full_chkpt(void)
{
    uint32_t pba_full;
    pba_full = (ptr_full == 0 ? PBA_FIRST_FULL : PBA_SECOND_FULL);
    /* Erase the commit record of full chkpt first */
    flash_erase(pba_full + BLOCKS_FULL, 1);
    /* Then flash_erase the full chkpt */
    flash_erase_bulk(pba_full, BLOCKS_FULL);
}

void apply_full_chkpt(void)
{
    uint32_t pba_full;
    pba_full = (ptr_full == 0 ? PBA_FIRST_FULL : PBA_SECOND_FULL);
    flash_read_bulk(pba_full, BLOCKS_FULL, l2p);
}

void find_committed_full_chkpt(void)
{
    flash_read(PBA_FIRST_FULL_COMMIT, 0, buf_tmp);
    ptr_full = (buf_tmp[0] == 0 ? 0 : 1);
}

void toggle_full_chkpt(void)
{
    ptr_full = (ptr_full + 1) % 2;
}
/* Full chkpt end */

uint32_t get_active_psa(void)
{
    return (pba_active * PAGES_PER_BLOCK + ipa_active) * SECTORS_PER_PAGE + isa_active;
}

uint32_t get_victim_psa(void)
{
    return (pba_gc * PAGES_PER_BLOCK + ipa_gc) * SECTORS_PER_PAGE + isa_gc;
}

__attribute__((noinline))
void create_one_delta_chkpt_when_delta_buf_full(void)
{
    if (delta_chkpt_buf_full()) {
        create_one_delta_chkpt(FLAG_DELTA_TENTATIVE);
        reset_delta_buf();
    }
}

__attribute__((noinline))
void persist_merge_buffer_when_full(void)
{
    if (merge_buf_full()) {
        persist_merge_buffer();
    }
}

__attribute__((noinline))
void make_one_erasable_block_free_when_free_blklist_empty(void)
{
    if (free_blklist_empty()) {
        make_one_erasable_block_free();
    }
}

void make_one_erasable_block_unless_erasable_blklist_empty(void)
{
    if (!erasable_blklist_empty()) {
        make_one_erasable_block_free();
    }
}

void ftl_read(uint32_t lsa, uint32_t *data)
{
    if (lsa >= N_LAS)
        return;

    if (lsa == lsas_merge[1]) {
        memcpy32(data, &buf_merge[N_ENTRIES_PER_SECTOR], N_ENTRIES_PER_SECTOR);
        return;
    }

    if (lsa == lsas_merge[0]) {
        memcpy32(data, &buf_merge[0], N_ENTRIES_PER_SECTOR);
        return;
    }

    uint32_t psa = l2p[lsa];
    flash_read(PSA_TO_PBA(psa), PSA_TO_IPA(psa), buf_read);
    memcpy32(data, &buf_read[PSA_TO_ISA(psa) * N_ENTRIES_PER_SECTOR], N_ENTRIES_PER_SECTOR);
}

void ftl_write(uint32_t lsa, uint32_t *data)
{
    if (lsa >= N_LAS || wcnt >= MAX_WCNT)
        return;

    make_one_erasable_block_free_when_free_blklist_empty();

    persist_merge_buffer_when_full();

    uint32_t psa_prev = l2p[lsa];
    p2l[psa_prev] = LSA_INVALID;
    vcnts[PSA_TO_PBA(psa_prev)]--;

    uint32_t psa = get_active_psa();
    l2p[lsa] = psa;
    p2l[psa] = lsa;
    vcnts[PSA_TO_PBA(psa)]++;
    lsa_gc = (lsa == lsa_gc) ? N_LAS : lsa_gc;

    copy_data_to_merge_buf(lsa, data);

    create_one_delta_chkpt_when_delta_buf_full();

    append_delta_pair(lsa, psa);

    wcnt++;
}

__attribute__((noinline))
void persist_merge_buffer_unless_empty(void)
{
    if (!merge_buf_empty()) {
        persist_merge_buffer();
    }
}

int ftl_flush_precond_holds(void)
{
    uint32_t n_ready_blks = 
        (usable <= used) ? (used - usable) : (used + BLOCKS_DATA - usable);
    return n_ready_blks >= 36;
}

void ftl_flush(void)
{
    check_sufficient_ready_blocks();
    make_one_erasable_block_free_when_free_blklist_empty();
    
    persist_merge_buffer_unless_empty();

    flash_sync();
    create_one_delta_chkpt(FLAG_DELTA_COMMITTED);
    reset_delta_buf();

    if (delta_chkpt_region_almost_full()) {
        create_full_chkpt();
        toggle_full_chkpt();
        delete_full_chkpt();
        delete_all_delta_chkpts();
    }

    make_all_invalid_blocks_erasable();

    gcprog = 0;
    wcnt = 0;
}

int reach_gc_threshold(void)
{
    uint64_t n_used_blks;
    n_used_blks = (used <= active) ? (active - used) : (active + BLOCKS_DATA - used);
    return (n_used_blks >= THRESHOLD_GC);
}

__attribute__((noinline))
void find_index_of_victim_block_body(void)
{
    if (vcnts[blk_list[idx]] < min_vcnt) {
        idx_victim = idx;
        min_vcnt = vcnts[blk_list[idx]];
    }

    idx = BLK_LIST_NEXT(idx);
}

__attribute__((noinline))
void find_index_of_victim_block_loop(void)
{
    while (idx != active)
        find_index_of_victim_block_body();
}

void swap_victim_block_to_head(void)
{
    idx = used;
    idx_victim = used;
    min_vcnt = vcnts[blk_list[idx_victim]];
    find_index_of_victim_block_loop();

    uint32_t pba_victim = blk_list[idx_victim];
    blk_list[idx_victim] = blk_list[used];
    blk_list[used] = pba_victim;
}

void choose_victim_block(void)
{
    swap_victim_block_to_head();
    pba_gc = blk_list[used];
}

void make_victim_block_invalid(void)
{
    used = BLK_LIST_NEXT(used);
}

void ftl_gc_copy(void)
{
    if (!enable_gc && !reach_gc_threshold())
        return;

    if (!enable_gc && reach_gc_threshold()) {
        ipa_gc = 0;
        isa_gc = 0;
        enable_gc = 1;
        choose_victim_block();
        lsa_gc = p2l[get_victim_psa()];
        return;
    }

    if (gcprog >= MAX_GCPROG)
        return;

    if (lsa_gc < N_LAS) {
        flash_read(pba_gc, ipa_gc, buf_gc);
        
        make_one_erasable_block_free_when_free_blklist_empty();

        persist_merge_buffer_when_full();

        uint32_t psa_gc = l2p[lsa_gc];
        p2l[psa_gc] = LSA_INVALID;
        vcnts[PSA_TO_PBA(psa_gc)]--;

        uint32_t psa_active = get_active_psa();
        l2p[lsa_gc] = psa_active;
        p2l[psa_active] = lsa_gc;
        vcnts[PSA_TO_PBA(psa_active)]++;

        copy_data_to_merge_buf(lsa_gc, &buf_gc[isa_gc * N_ENTRIES_PER_SECTOR]);

        create_one_delta_chkpt_when_delta_buf_full();
        append_delta_pair(lsa_gc, psa_active);

        gcprog++;
    }

    isa_gc++;
    if (isa_gc == SECTORS_PER_PAGE) {
        isa_gc = 0;
        ipa_gc++;

        if (ipa_gc == PAGES_PER_BLOCK) {
            make_victim_block_invalid();
            ipa_gc = 0;
            enable_gc = 0;
        }
    }
    lsa_gc = p2l[get_victim_psa()];
}

void ftl_gc_erase(void)
{
    make_one_erasable_block_unless_erasable_blklist_empty();
}

__attribute__((noinline))
void reset_committed_point_when_first_delta_page_erased(void)
{
    if (first_delta_page_erased()) {
        reset_committed_point();
    }
}

void reconstruct_p2l(void)
{
    invalidate_p2l();
    remap_valid_sectors();
}

void reconstruct_vcnts(void)
{
    reset_vcnts();
    count_valid_sectors();
}

void ftl_recovery(void)
{
    /* Apply a committed full chkpt */
    find_committed_full_chkpt();
    apply_full_chkpt();

    /* Sequentially apply delta chkpts until the last committed one */
    find_last_committed_delta_chkpt();
    reset_committed_point_when_first_delta_page_erased();
    apply_delta_chkpt();
    l2p[N_LAS] = N_PAS;

    /* Recover the full and delta chkpts to a state satisfying RI and AR */
    flash_sync();
    reset_delta_buf();
    toggle_full_chkpt();
    delete_full_chkpt();
    create_full_chkpt();
    toggle_full_chkpt();
    delete_full_chkpt();
    delete_all_delta_chkpts();

    /* Recover other metadata */
    reconstruct_p2l();
    reconstruct_vcnts();
    reconstruct_block_list();
    check_sufficient_avail_blocks();
    make_one_erasable_block_free();
    invalidate_merge_buffer();
    reset_data_pointer();
    reset_gc_pointer();
    check_l2p_injective();

    gcprog = 0;
    wcnt = 0;
}

void ftl_format(void)
{
    flash_erase_bulk(0, BLOCKS_TOTAL + 1);
    memset32(l2p, N_PAS, N_LAS + 1);
    ptr_full = 0;
    create_full_chkpt();
    memset32(buf_tmp, -1, N_ENTRIES_PER_PAGE);
    flash_program(BLOCKS_TOTAL, 0, buf_tmp, 1);
}
