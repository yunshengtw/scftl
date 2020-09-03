; ModuleID = '../src/ftl.c'
source_filename = "../src/ftl.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@erasable = common dso_local local_unnamed_addr global i64 0, align 8
@failed = common dso_local local_unnamed_addr global i32 0, align 4
@usable = common dso_local local_unnamed_addr global i64 0, align 8
@used = common dso_local local_unnamed_addr global i64 0, align 8
@l2p = common dso_local global [1048576 x i32] zeroinitializer, align 16
@sectid = common dso_local local_unnamed_addr global i32 0, align 4
@pa_used = common dso_local global [1642497 x i8] zeroinitializer, align 16
@blk_list = common dso_local local_unnamed_addr global [1536 x i32] zeroinitializer, align 16
@pba_active = common dso_local local_unnamed_addr global i32 0, align 4
@active = common dso_local local_unnamed_addr global i64 0, align 8
@invalid = common dso_local local_unnamed_addr global i64 0, align 8
@is_used = common dso_local global [1537 x i8] zeroinitializer, align 16
@idx = common dso_local local_unnamed_addr global i64 0, align 8
@blkid = common dso_local local_unnamed_addr global i32 0, align 4
@lsas_merge = common dso_local local_unnamed_addr global [2 x i32] zeroinitializer, align 4
@isa_active = common dso_local local_unnamed_addr global i32 0, align 4
@ipa_active = common dso_local local_unnamed_addr global i32 0, align 4
@enable_gc = common dso_local local_unnamed_addr global i32 0, align 4
@ipa_gc = common dso_local local_unnamed_addr global i32 0, align 4
@isa_gc = common dso_local local_unnamed_addr global i32 0, align 4
@pba_gc = common dso_local local_unnamed_addr global i32 0, align 4
@lsa_gc = common dso_local local_unnamed_addr global i32 0, align 4
@buf_merge = common dso_local global [2048 x i32] zeroinitializer, align 16
@p2l = common dso_local local_unnamed_addr global [1642497 x i32] zeroinitializer, align 16
@pba_committed = common dso_local local_unnamed_addr global i32 0, align 4
@ipa_committed = common dso_local local_unnamed_addr global i32 0, align 4
@pgid = common dso_local local_unnamed_addr global i32 0, align 4
@buf_tmp = common dso_local global [2048 x i32] zeroinitializer, align 16
@vcnts = common dso_local local_unnamed_addr global [1605 x i16] zeroinitializer, align 16
@delta_buf = common dso_local global [2048 x i32] zeroinitializer, align 16
@ptr_delta_buf = common dso_local local_unnamed_addr global i32 0, align 4
@ipa_delta = common dso_local local_unnamed_addr global i32 0, align 4
@pba_delta = common dso_local local_unnamed_addr global i32 0, align 4
@ptr_full = common dso_local local_unnamed_addr global i32 0, align 4
@buf_commit = common dso_local global [2048 x i32] zeroinitializer, align 16
@buf_read = common dso_local global [2048 x i32] zeroinitializer, align 16
@wcnt = common dso_local local_unnamed_addr global i32 0, align 4
@gcprog = common dso_local local_unnamed_addr global i32 0, align 4
@min_vcnt = common dso_local local_unnamed_addr global i16 0, align 2
@idx_victim = common dso_local local_unnamed_addr global i64 0, align 8
@buf_gc = common dso_local global [2048 x i32] zeroinitializer, align 16
@host_data = common dso_local local_unnamed_addr global [1024 x i32] zeroinitializer, align 16

; Function Attrs: nofree noinline norecurse nounwind
define dso_local i8* @memcpy32(i32* %dst, i32* nocapture readonly %src, i64 %len) local_unnamed_addr #0 {
entry:
  %cmp7 = icmp eq i64 %len, 0
  br i1 %cmp7, label %for.end, label %for.body.preheader

for.body.preheader:                               ; preds = %entry
  %0 = add i64 %len, -1
  %xtraiter = and i64 %len, 3
  %1 = icmp ult i64 %0, 3
  br i1 %1, label %for.end.loopexit.unr-lcssa, label %for.body.preheader.new

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = sub i64 %len, %xtraiter
  br label %for.body

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %i.08 = phi i64 [ 0, %for.body.preheader.new ], [ %inc.3, %for.body ]
  %niter = phi i64 [ %unroll_iter, %for.body.preheader.new ], [ %niter.nsub.3, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %src, i64 %i.08
  %2 = load i32, i32* %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, i32* %dst, i64 %i.08
  store i32 %2, i32* %arrayidx1, align 4
  %inc = or i64 %i.08, 1
  %arrayidx.1 = getelementptr inbounds i32, i32* %src, i64 %inc
  %3 = load i32, i32* %arrayidx.1, align 4
  %arrayidx1.1 = getelementptr inbounds i32, i32* %dst, i64 %inc
  store i32 %3, i32* %arrayidx1.1, align 4
  %inc.1 = or i64 %i.08, 2
  %arrayidx.2 = getelementptr inbounds i32, i32* %src, i64 %inc.1
  %4 = load i32, i32* %arrayidx.2, align 4
  %arrayidx1.2 = getelementptr inbounds i32, i32* %dst, i64 %inc.1
  store i32 %4, i32* %arrayidx1.2, align 4
  %inc.2 = or i64 %i.08, 3
  %arrayidx.3 = getelementptr inbounds i32, i32* %src, i64 %inc.2
  %5 = load i32, i32* %arrayidx.3, align 4
  %arrayidx1.3 = getelementptr inbounds i32, i32* %dst, i64 %inc.2
  store i32 %5, i32* %arrayidx1.3, align 4
  %inc.3 = add nuw i64 %i.08, 4
  %niter.nsub.3 = add i64 %niter, -4
  %niter.ncmp.3 = icmp eq i64 %niter.nsub.3, 0
  br i1 %niter.ncmp.3, label %for.end.loopexit.unr-lcssa, label %for.body

for.end.loopexit.unr-lcssa:                       ; preds = %for.body, %for.body.preheader
  %i.08.unr = phi i64 [ 0, %for.body.preheader ], [ %inc.3, %for.body ]
  %lcmp.mod = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod, label %for.end, label %for.body.epil

for.body.epil:                                    ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil
  %i.08.epil = phi i64 [ %inc.epil, %for.body.epil ], [ %i.08.unr, %for.end.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.sub, %for.body.epil ], [ %xtraiter, %for.end.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds i32, i32* %src, i64 %i.08.epil
  %6 = load i32, i32* %arrayidx.epil, align 4
  %arrayidx1.epil = getelementptr inbounds i32, i32* %dst, i64 %i.08.epil
  store i32 %6, i32* %arrayidx1.epil, align 4
  %inc.epil = add nuw i64 %i.08.epil, 1
  %epil.iter.sub = add i64 %epil.iter, -1
  %epil.iter.cmp = icmp eq i64 %epil.iter.sub, 0
  br i1 %epil.iter.cmp, label %for.end, label %for.body.epil, !llvm.loop !2

for.end:                                          ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil, %entry
  %7 = bitcast i32* %dst to i8*
  ret i8* %7
}

; Function Attrs: nofree noinline norecurse nounwind writeonly
define dso_local i32* @memset32(i32* returned %p, i32 %v, i64 %len) local_unnamed_addr #1 {
entry:
  %cmp5 = icmp eq i64 %len, 0
  br i1 %cmp5, label %for.end, label %for.body.preheader

for.body.preheader:                               ; preds = %entry
  %0 = add i64 %len, -1
  %xtraiter = and i64 %len, 7
  %1 = icmp ult i64 %0, 7
  br i1 %1, label %for.end.loopexit.unr-lcssa, label %for.body.preheader.new

for.body.preheader.new:                           ; preds = %for.body.preheader
  %unroll_iter = sub i64 %len, %xtraiter
  br label %for.body

for.body:                                         ; preds = %for.body, %for.body.preheader.new
  %i.06 = phi i64 [ 0, %for.body.preheader.new ], [ %inc.7, %for.body ]
  %niter = phi i64 [ %unroll_iter, %for.body.preheader.new ], [ %niter.nsub.7, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %p, i64 %i.06
  store i32 %v, i32* %arrayidx, align 4
  %inc = or i64 %i.06, 1
  %arrayidx.1 = getelementptr inbounds i32, i32* %p, i64 %inc
  store i32 %v, i32* %arrayidx.1, align 4
  %inc.1 = or i64 %i.06, 2
  %arrayidx.2 = getelementptr inbounds i32, i32* %p, i64 %inc.1
  store i32 %v, i32* %arrayidx.2, align 4
  %inc.2 = or i64 %i.06, 3
  %arrayidx.3 = getelementptr inbounds i32, i32* %p, i64 %inc.2
  store i32 %v, i32* %arrayidx.3, align 4
  %inc.3 = or i64 %i.06, 4
  %arrayidx.4 = getelementptr inbounds i32, i32* %p, i64 %inc.3
  store i32 %v, i32* %arrayidx.4, align 4
  %inc.4 = or i64 %i.06, 5
  %arrayidx.5 = getelementptr inbounds i32, i32* %p, i64 %inc.4
  store i32 %v, i32* %arrayidx.5, align 4
  %inc.5 = or i64 %i.06, 6
  %arrayidx.6 = getelementptr inbounds i32, i32* %p, i64 %inc.5
  store i32 %v, i32* %arrayidx.6, align 4
  %inc.6 = or i64 %i.06, 7
  %arrayidx.7 = getelementptr inbounds i32, i32* %p, i64 %inc.6
  store i32 %v, i32* %arrayidx.7, align 4
  %inc.7 = add nuw i64 %i.06, 8
  %niter.nsub.7 = add i64 %niter, -8
  %niter.ncmp.7 = icmp eq i64 %niter.nsub.7, 0
  br i1 %niter.ncmp.7, label %for.end.loopexit.unr-lcssa, label %for.body

for.end.loopexit.unr-lcssa:                       ; preds = %for.body, %for.body.preheader
  %i.06.unr = phi i64 [ 0, %for.body.preheader ], [ %inc.7, %for.body ]
  %lcmp.mod = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod, label %for.end, label %for.body.epil

for.body.epil:                                    ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil
  %i.06.epil = phi i64 [ %inc.epil, %for.body.epil ], [ %i.06.unr, %for.end.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.sub, %for.body.epil ], [ %xtraiter, %for.end.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds i32, i32* %p, i64 %i.06.epil
  store i32 %v, i32* %arrayidx.epil, align 4
  %inc.epil = add nuw i64 %i.06.epil, 1
  %epil.iter.sub = add i64 %epil.iter, -1
  %epil.iter.cmp = icmp eq i64 %epil.iter.sub, 0
  br i1 %epil.iter.cmp, label %for.end, label %for.body.epil, !llvm.loop !4

for.end:                                          ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil, %entry
  ret i32* %p
}

; Function Attrs: nofree noinline norecurse nounwind writeonly
define dso_local i8* @memset(i8* returned %p, i32 %c, i64 %len) local_unnamed_addr #1 {
entry:
  %cmp6 = icmp eq i64 %len, 0
  br i1 %cmp6, label %for.end, label %for.body.lr.ph

for.body.lr.ph:                                   ; preds = %entry
  %conv = trunc i32 %c to i8
  %0 = add i64 %len, -1
  %xtraiter = and i64 %len, 7
  %1 = icmp ult i64 %0, 7
  br i1 %1, label %for.end.loopexit.unr-lcssa, label %for.body.lr.ph.new

for.body.lr.ph.new:                               ; preds = %for.body.lr.ph
  %unroll_iter = sub i64 %len, %xtraiter
  br label %for.body

for.body:                                         ; preds = %for.body, %for.body.lr.ph.new
  %i.07 = phi i64 [ 0, %for.body.lr.ph.new ], [ %inc.7, %for.body ]
  %niter = phi i64 [ %unroll_iter, %for.body.lr.ph.new ], [ %niter.nsub.7, %for.body ]
  %arrayidx = getelementptr inbounds i8, i8* %p, i64 %i.07
  store i8 %conv, i8* %arrayidx, align 1
  %inc = or i64 %i.07, 1
  %arrayidx.1 = getelementptr inbounds i8, i8* %p, i64 %inc
  store i8 %conv, i8* %arrayidx.1, align 1
  %inc.1 = or i64 %i.07, 2
  %arrayidx.2 = getelementptr inbounds i8, i8* %p, i64 %inc.1
  store i8 %conv, i8* %arrayidx.2, align 1
  %inc.2 = or i64 %i.07, 3
  %arrayidx.3 = getelementptr inbounds i8, i8* %p, i64 %inc.2
  store i8 %conv, i8* %arrayidx.3, align 1
  %inc.3 = or i64 %i.07, 4
  %arrayidx.4 = getelementptr inbounds i8, i8* %p, i64 %inc.3
  store i8 %conv, i8* %arrayidx.4, align 1
  %inc.4 = or i64 %i.07, 5
  %arrayidx.5 = getelementptr inbounds i8, i8* %p, i64 %inc.4
  store i8 %conv, i8* %arrayidx.5, align 1
  %inc.5 = or i64 %i.07, 6
  %arrayidx.6 = getelementptr inbounds i8, i8* %p, i64 %inc.5
  store i8 %conv, i8* %arrayidx.6, align 1
  %inc.6 = or i64 %i.07, 7
  %arrayidx.7 = getelementptr inbounds i8, i8* %p, i64 %inc.6
  store i8 %conv, i8* %arrayidx.7, align 1
  %inc.7 = add nuw i64 %i.07, 8
  %niter.nsub.7 = add i64 %niter, -8
  %niter.ncmp.7 = icmp eq i64 %niter.nsub.7, 0
  br i1 %niter.ncmp.7, label %for.end.loopexit.unr-lcssa, label %for.body

for.end.loopexit.unr-lcssa:                       ; preds = %for.body, %for.body.lr.ph
  %i.07.unr = phi i64 [ 0, %for.body.lr.ph ], [ %inc.7, %for.body ]
  %lcmp.mod = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod, label %for.end, label %for.body.epil

for.body.epil:                                    ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil
  %i.07.epil = phi i64 [ %inc.epil, %for.body.epil ], [ %i.07.unr, %for.end.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.sub, %for.body.epil ], [ %xtraiter, %for.end.loopexit.unr-lcssa ]
  %arrayidx.epil = getelementptr inbounds i8, i8* %p, i64 %i.07.epil
  store i8 %conv, i8* %arrayidx.epil, align 1
  %inc.epil = add nuw i64 %i.07.epil, 1
  %epil.iter.sub = add i64 %epil.iter, -1
  %epil.iter.cmp = icmp eq i64 %epil.iter.sub, 0
  br i1 %epil.iter.cmp, label %for.end, label %for.body.epil, !llvm.loop !5

for.end:                                          ; preds = %for.end.loopexit.unr-lcssa, %for.body.epil, %entry
  ret i8* %p
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @check_sufficient_avail_blocks() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @erasable, align 8
  %cmp = icmp ugt i64 %0, 1500
  %. = zext i1 %cmp to i32
  store i32 %., i32* @failed, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @check_sufficient_ready_blocks() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @usable, align 8
  %1 = load i64, i64* @used, align 8
  %cmp = icmp ult i64 %1, %0
  %add = add i64 %1, 1536
  %.pn = select i1 %cmp, i64 %add, i64 %1
  %cond = sub i64 %.pn, %0
  %conv = trunc i64 %cond to i32
  %cmp2 = icmp ult i32 %conv, 36
  %. = zext i1 %cmp2 to i32
  store i32 %., i32* @failed, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @check_l2p_injective_body() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %idxprom = zext i32 %0 to i64
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %cmp = icmp eq i32 %1, 1642496
  br i1 %cmp, label %if.end, label %land.lhs.true

land.lhs.true:                                    ; preds = %entry
  %idxprom1 = zext i32 %1 to i64
  %arrayidx2 = getelementptr inbounds [1642497 x i8], [1642497 x i8]* @pa_used, i64 0, i64 %idxprom1
  %2 = load i8, i8* %arrayidx2, align 1
  %cmp3 = icmp eq i8 %2, 1
  br i1 %cmp3, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true
  store i32 1, i32* @failed, align 4
  br label %if.end

if.end:                                           ; preds = %entry, %if.then, %land.lhs.true
  %idxprom5.pre-phi = phi i64 [ %idxprom1, %if.then ], [ %idxprom1, %land.lhs.true ], [ 1642496, %entry ]
  %arrayidx6 = getelementptr inbounds [1642497 x i8], [1642497 x i8]* @pa_used, i64 0, i64 %idxprom5.pre-phi
  store i8 1, i8* %arrayidx6, align 1
  %inc = add i32 %0, 1
  store i32 %inc, i32* @sectid, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @check_l2p_injective_loop() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %cmp1 = icmp eq i32 %0, 1048575
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @check_l2p_injective_body() #8
  %1 = load i32, i32* @sectid, align 4
  %cmp = icmp eq i32 %1, 1048575
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @check_l2p_injective() local_unnamed_addr #0 {
entry:
  store i32 0, i32* @sectid, align 4
  store i32 0, i32* @failed, align 4
  %call = tail call i8* @memset(i8* getelementptr inbounds ([1642497 x i8], [1642497 x i8]* @pa_used, i64 0, i64 0), i32 0, i64 1642497) #8
  tail call void @check_l2p_injective_loop() #8
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @choose_free_block() local_unnamed_addr #2 {
entry:
  %0 = load i64, i64* @usable, align 8
  %arrayidx = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx, align 4
  store i32 %1, i32* @pba_active, align 4
  store i64 %0, i64* @active, align 8
  %cmp = icmp eq i64 %0, 1535
  %add = add i64 %0, 1
  %cond = select i1 %cmp, i64 0, i64 %add
  store i64 %cond, i64* @usable, align 8
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @make_all_invalid_blocks_erasable() local_unnamed_addr #2 {
entry:
  %0 = load i64, i64* @used, align 8
  store i64 %0, i64* @invalid, align 8
  ret void
}

; Function Attrs: nounwind
define dso_local void @make_one_erasable_block_free() local_unnamed_addr #3 {
entry:
  %0 = load i64, i64* @erasable, align 8
  %arrayidx = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx, align 4
  tail call void @flash_erase(i32 %1, i32 0) #9
  %2 = load i64, i64* @erasable, align 8
  %cmp = icmp eq i64 %2, 1535
  %add = add i64 %2, 1
  %cond = select i1 %cmp, i64 0, i64 %add
  store i64 %cond, i64* @erasable, align 8
  ret void
}

declare dso_local void @flash_erase(i32, i32) local_unnamed_addr #4

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @free_blklist_empty() local_unnamed_addr #5 {
entry:
  %0 = load i64, i64* @usable, align 8
  %1 = load i64, i64* @erasable, align 8
  %cmp = icmp eq i64 %0, %1
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @erasable_blklist_empty() local_unnamed_addr #5 {
entry:
  %0 = load i64, i64* @erasable, align 8
  %1 = load i64, i64* @invalid, align 8
  %cmp = icmp eq i64 %0, %1
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @categorize_used_and_erasable_blocks_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [1537 x i8], [1537 x i8]* @is_used, i64 0, i64 %0
  %1 = load i8, i8* %arrayidx, align 1
  %tobool = icmp eq i8 %1, 0
  br i1 %tobool, label %if.else, label %if.then

if.then:                                          ; preds = %entry
  %2 = load i64, i64* @erasable, align 8
  %arrayidx1 = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %2
  %3 = load i32, i32* %arrayidx1, align 4
  %arrayidx2 = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  store i32 %3, i32* %arrayidx2, align 4
  %4 = load i32, i32* @blkid, align 4
  store i32 %4, i32* %arrayidx1, align 4
  %inc = add i64 %2, 1
  store i64 %inc, i64* @erasable, align 8
  br label %if.end

if.else:                                          ; preds = %entry
  %5 = load i32, i32* @blkid, align 4
  %arrayidx4 = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  store i32 %5, i32* %arrayidx4, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %6 = phi i32 [ %5, %if.else ], [ %4, %if.then ]
  %inc5 = add i64 %0, 1
  store i64 %inc5, i64* @idx, align 8
  %inc6 = add i32 %6, 1
  store i32 %inc6, i32* @blkid, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @categorize_used_and_erasable_blocks_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %cmp1 = icmp eq i64 %0, 1536
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @categorize_used_and_erasable_blocks_body() #8
  %1 = load i64, i64* @idx, align 8
  %cmp = icmp eq i64 %1, 1536
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @categorize_used_and_erasable_blocks() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  store i32 68, i32* @blkid, align 4
  tail call void @categorize_used_and_erasable_blocks_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @identify_used_blocks_body() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %idxprom = zext i32 %0 to i64
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %div = lshr i32 %1, 10
  %sub = add nsw i32 %div, -68
  %idxprom1 = zext i32 %sub to i64
  %arrayidx2 = getelementptr inbounds [1537 x i8], [1537 x i8]* @is_used, i64 0, i64 %idxprom1
  store i8 1, i8* %arrayidx2, align 1
  %inc = add i32 %0, 1
  store i32 %inc, i32* @sectid, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @identify_used_blocks_loop() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %cmp1 = icmp eq i32 %0, 1048575
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @identify_used_blocks_body() #8
  %1 = load i32, i32* @sectid, align 4
  %cmp = icmp eq i32 %1, 1048575
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @identify_used_blocks() local_unnamed_addr #2 {
entry:
  store i32 0, i32* @sectid, align 4
  tail call void @identify_used_blocks_loop() #8
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @reconstruct_block_list() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @erasable, align 8
  store i64 0, i64* @invalid, align 8
  store i64 0, i64* @used, align 8
  %call = tail call i8* @memset(i8* getelementptr inbounds ([1537 x i8], [1537 x i8]* @is_used, i64 0, i64 0), i32 0, i64 1537) #8
  store i32 0, i32* @sectid, align 4
  tail call void @identify_used_blocks_loop() #9
  store i64 0, i64* @idx, align 8
  store i32 68, i32* @blkid, align 4
  tail call void @categorize_used_and_erasable_blocks_loop() #9
  %0 = load i64, i64* @erasable, align 8
  store i64 %0, i64* @usable, align 8
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define dso_local void @invalidate_merge_buffer() local_unnamed_addr #6 {
entry:
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 0), align 4
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 1), align 4
  store i32 0, i32* @isa_active, align 4
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @reset_data_pointer() local_unnamed_addr #2 {
entry:
  store i32 0, i32* @ipa_active, align 4
  %0 = load i64, i64* @usable, align 8
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx.i, align 4
  store i32 %1, i32* @pba_active, align 4
  store i64 %0, i64* @active, align 8
  %cmp.i = icmp eq i64 %0, 1535
  %add.i = add i64 %0, 1
  %cond.i = select i1 %cmp.i, i64 0, i64 %add.i
  store i64 %cond.i, i64* @usable, align 8
  ret void
}

; Function Attrs: nofree norecurse nounwind writeonly
define dso_local void @reset_gc_pointer() local_unnamed_addr #6 {
entry:
  store i32 0, i32* @enable_gc, align 4
  store i32 0, i32* @ipa_gc, align 4
  store i32 0, i32* @isa_gc, align 4
  store i32 68, i32* @pba_gc, align 4
  store i32 1048575, i32* @lsa_gc, align 4
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @persist_merge_buffer() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @pba_active, align 4
  %1 = load i32, i32* @ipa_active, align 4
  tail call void @flash_program(i32 %0, i32 %1, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_merge, i64 0, i64 0), i32 0) #9
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 0), align 4
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 1), align 4
  store i32 0, i32* @isa_active, align 4
  %2 = load i32, i32* @ipa_active, align 4
  %inc = add i32 %2, 1
  store i32 %inc, i32* @ipa_active, align 4
  %cmp = icmp eq i32 %inc, 512
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  store i32 0, i32* @ipa_active, align 4
  %3 = load i64, i64* @usable, align 8
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %3
  %4 = load i32, i32* %arrayidx.i, align 4
  store i32 %4, i32* @pba_active, align 4
  store i64 %3, i64* @active, align 8
  %cmp.i = icmp eq i64 %3, 1535
  %add.i = add i64 %3, 1
  %cond.i = select i1 %cmp.i, i64 0, i64 %add.i
  store i64 %cond.i, i64* @usable, align 8
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  ret void
}

declare dso_local void @flash_program(i32, i32, i32*, i32) local_unnamed_addr #4

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @merge_buf_full() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @isa_active, align 4
  %cmp = icmp eq i32 %0, 2
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @merge_buf_empty() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @isa_active, align 4
  %cmp = icmp eq i32 %0, 0
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @copy_data_to_merge_buf(i32 %lsa, i32* nocapture readonly %data) local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @isa_active, align 4
  %mul = shl i32 %0, 10
  %idxprom = zext i32 %mul to i64
  %arrayidx = getelementptr inbounds [2048 x i32], [2048 x i32]* @buf_merge, i64 0, i64 %idxprom
  %call = tail call i8* @memcpy32(i32* nonnull %arrayidx, i32* %data, i64 1024) #8
  %1 = load i32, i32* @isa_active, align 4
  %idxprom1 = zext i32 %1 to i64
  %arrayidx2 = getelementptr inbounds [2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 %idxprom1
  store i32 %lsa, i32* %arrayidx2, align 4
  %inc = add i32 %1, 1
  store i32 %inc, i32* @isa_active, align 4
  ret void
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @gc_page_valid() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @pba_gc, align 4
  %mul = shl i32 %0, 9
  %1 = load i32, i32* @ipa_gc, align 4
  %add = add i32 %mul, %1
  %mul1 = shl i32 %add, 1
  %2 = zext i32 %mul1 to i64
  %arrayidx = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %2
  %3 = load i32, i32* %arrayidx, align 8
  %cmp3 = icmp ne i32 %3, 1048575
  %4 = or i64 %2, 1
  %arrayidx.1 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %4
  %5 = load i32, i32* %arrayidx.1, align 4
  %cmp3.1 = icmp ne i32 %5, 1048575
  %or.113 = or i1 %cmp3, %cmp3.1
  %or.1 = zext i1 %or.113 to i32
  ret i32 %or.1
}

; Function Attrs: nofree norecurse nounwind writeonly
define dso_local void @reset_committed_point() local_unnamed_addr #6 {
entry:
  store i32 0, i32* @pba_committed, align 4
  store i32 0, i32* @ipa_committed, align 4
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @find_last_committed_delta_chkpt_body() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @blkid, align 4
  %1 = load i32, i32* @pgid, align 4
  tail call void @flash_read(i32 %0, i32 %1, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  %2 = load i32, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), align 16
  %cmp = icmp eq i32 %2, 0
  br i1 %cmp, label %if.then, label %entry.if.end_crit_edge

entry.if.end_crit_edge:                           ; preds = %entry
  %.pre = load i32, i32* @pgid, align 4
  br label %if.end

if.then:                                          ; preds = %entry
  %3 = load i32, i32* @blkid, align 4
  store i32 %3, i32* @pba_committed, align 4
  %4 = load i32, i32* @pgid, align 4
  %add = add i32 %4, 1
  store i32 %add, i32* @ipa_committed, align 4
  br label %if.end

if.end:                                           ; preds = %entry.if.end_crit_edge, %if.then
  %5 = phi i32 [ %.pre, %entry.if.end_crit_edge ], [ %4, %if.then ]
  %inc = add i32 %5, 1
  store i32 %inc, i32* @pgid, align 4
  %cmp1 = icmp eq i32 %inc, 512
  br i1 %cmp1, label %if.then2, label %if.end4

if.then2:                                         ; preds = %if.end
  store i32 0, i32* @pgid, align 4
  %6 = load i32, i32* @blkid, align 4
  %inc3 = add i32 %6, 1
  store i32 %inc3, i32* @blkid, align 4
  br label %if.end4

if.end4:                                          ; preds = %if.then2, %if.end
  ret void
}

declare dso_local void @flash_read(i32, i32, i32*) local_unnamed_addr #4

; Function Attrs: noinline nounwind
define dso_local void @find_last_committed_delta_chkpt_loop() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @blkid, align 4
  %cmp1 = icmp eq i32 %0, 64
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @find_last_committed_delta_chkpt_body() #8
  %1 = load i32, i32* @blkid, align 4
  %cmp = icmp eq i32 %1, 64
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nounwind
define dso_local void @find_last_committed_delta_chkpt() local_unnamed_addr #3 {
entry:
  store i32 0, i32* @pba_committed, align 4
  store i32 0, i32* @ipa_committed, align 4
  store i32 0, i32* @blkid, align 4
  store i32 0, i32* @pgid, align 4
  tail call void @find_last_committed_delta_chkpt_loop() #8
  ret void
}

; Function Attrs: nounwind
define dso_local i32 @first_delta_page_erased() local_unnamed_addr #3 {
entry:
  tail call void @flash_read(i32 0, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  %0 = load i32, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), align 16
  %1 = icmp ugt i32 %0, 1
  %land.ext = zext i1 %1 to i32
  ret i32 %land.ext
}

; Function Attrs: noinline nounwind
define dso_local void @apply_delta_chkpt_body() local_unnamed_addr #7 {
entry:
  %0 = load i64, i64* @idx, align 8
  %tobool = icmp eq i64 %0, 0
  br i1 %tobool, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %1 = load i32, i32* @blkid, align 4
  %2 = load i32, i32* @pgid, align 4
  tail call void @flash_read(i32 %1, i32 %2, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  %3 = load i32, i32* @blkid, align 4
  %4 = load i32, i32* @pba_committed, align 4
  %cmp = icmp ugt i32 %3, %4
  br i1 %cmp, label %if.end7, label %lor.lhs.false

lor.lhs.false:                                    ; preds = %if.end
  %cmp1 = icmp eq i32 %3, %4
  br i1 %cmp1, label %land.lhs.true, label %if.then3

land.lhs.true:                                    ; preds = %lor.lhs.false
  %5 = load i32, i32* @pgid, align 4
  %6 = load i32, i32* @ipa_committed, align 4
  %cmp2 = icmp ult i32 %5, %6
  br i1 %cmp2, label %if.then3, label %if.end7

if.then3:                                         ; preds = %land.lhs.true, %lor.lhs.false
  %7 = load i64, i64* @idx, align 8
  %add = add i64 %7, 2
  %arrayidx = getelementptr inbounds [2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 %add
  %8 = load i32, i32* %arrayidx, align 4
  %add4 = add i64 %7, 1025
  %arrayidx5 = getelementptr inbounds [2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 %add4
  %9 = load i32, i32* %arrayidx5, align 4
  %idxprom = zext i32 %8 to i64
  %arrayidx6 = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  store i32 %9, i32* %arrayidx6, align 4
  br label %if.end7

if.end7:                                          ; preds = %land.lhs.true, %if.then3, %if.end
  %10 = load i64, i64* @idx, align 8
  %inc = add i64 %10, 1
  store i64 %inc, i64* @idx, align 8
  %cmp8 = icmp eq i64 %inc, 1023
  br i1 %cmp8, label %if.then9, label %if.end11thread-pre-split

if.then9:                                         ; preds = %if.end7
  store i64 0, i64* @idx, align 8
  %11 = load i32, i32* @pgid, align 4
  %inc10 = add i32 %11, 1
  store i32 %inc10, i32* @pgid, align 4
  br label %if.end11

if.end11thread-pre-split:                         ; preds = %if.end7
  %.pr = load i32, i32* @pgid, align 4
  br label %if.end11

if.end11:                                         ; preds = %if.end11thread-pre-split, %if.then9
  %12 = phi i32 [ %.pr, %if.end11thread-pre-split ], [ %inc10, %if.then9 ]
  %cmp12 = icmp eq i32 %12, 512
  br i1 %cmp12, label %if.then13, label %if.end15

if.then13:                                        ; preds = %if.end11
  store i32 0, i32* @pgid, align 4
  %inc14 = add i32 %3, 1
  store i32 %inc14, i32* @blkid, align 4
  br label %if.end15

if.end15:                                         ; preds = %if.then13, %if.end11
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @apply_delta_chkpt_loop() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @blkid, align 4
  %cmp1 = icmp eq i32 %0, 64
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @apply_delta_chkpt_body() #8
  %1 = load i32, i32* @blkid, align 4
  %cmp = icmp eq i32 %1, 64
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nounwind
define dso_local void @apply_delta_chkpt() local_unnamed_addr #3 {
entry:
  store i32 0, i32* @blkid, align 4
  store i32 0, i32* @pgid, align 4
  store i64 0, i64* @idx, align 8
  tail call void @apply_delta_chkpt_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @invalidate_p2l_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %0
  store i32 1048575, i32* %arrayidx, align 4
  %inc = add i64 %0, 1
  store i64 %inc, i64* @idx, align 8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @invalidate_p2l_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %cmp1 = icmp eq i64 %0, 1642497
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @invalidate_p2l_body() #8
  %1 = load i64, i64* @idx, align 8
  %cmp = icmp eq i64 %1, 1642497
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @invalidate_p2l() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  tail call void @invalidate_p2l_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @reset_vcnts_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %0
  store i16 0, i16* %arrayidx, align 2
  %inc = add i64 %0, 1
  store i64 %inc, i64* @idx, align 8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @reset_vcnts_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %cmp1 = icmp eq i64 %0, 1604
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @reset_vcnts_body() #8
  %1 = load i64, i64* @idx, align 8
  %cmp = icmp eq i64 %1, 1604
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @reset_vcnts() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  tail call void @reset_vcnts_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @count_valid_sectors_body() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %idxprom = zext i32 %0 to i64
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %div = lshr i32 %1, 10
  %idxprom1 = zext i32 %div to i64
  %arrayidx2 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom1
  %2 = load i16, i16* %arrayidx2, align 2
  %inc = add i16 %2, 1
  store i16 %inc, i16* %arrayidx2, align 2
  %inc3 = add i32 %0, 1
  store i32 %inc3, i32* @sectid, align 4
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @count_valid_sectors_loop() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @sectid, align 4
  %cmp1 = icmp eq i32 %0, 1048575
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @count_valid_sectors_body() #8
  %1 = load i32, i32* @sectid, align 4
  %cmp = icmp eq i32 %1, 1048575
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @count_valid_sectors() local_unnamed_addr #2 {
entry:
  store i32 0, i32* @sectid, align 4
  tail call void @count_valid_sectors_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @remap_valid_sectors_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx, align 4
  %cmp = icmp ult i32 %1, 1642496
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %conv = trunc i64 %0 to i32
  %idxprom = zext i32 %1 to i64
  %arrayidx1 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom
  store i32 %conv, i32* %arrayidx1, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  %inc = add i64 %0, 1
  store i64 %inc, i64* @idx, align 8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @remap_valid_sectors_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %cmp1 = icmp eq i64 %0, 1048575
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @remap_valid_sectors_body() #8
  %1 = load i64, i64* @idx, align 8
  %cmp = icmp eq i64 %1, 1048575
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @remap_valid_sectors() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  tail call void @remap_valid_sectors_loop() #8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @invalidate_delta_buf_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %0
  store i32 1048575, i32* %arrayidx, align 4
  %inc = add i64 %0, 1
  store i64 %inc, i64* @idx, align 8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @invalidate_delta_buf_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %cmp1 = icmp eq i64 %0, 1025
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @invalidate_delta_buf_body() #8
  %1 = load i64, i64* @idx, align 8
  %cmp = icmp eq i64 %1, 1025
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @invalidate_delta_buf() local_unnamed_addr #2 {
entry:
  store i64 2, i64* @idx, align 8
  tail call void @invalidate_delta_buf_loop() #8
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @append_delta_pair(i32 %la, i32 %pa) local_unnamed_addr #2 {
entry:
  %0 = load i32, i32* @ptr_delta_buf, align 4
  %add = add i32 %0, 2
  %idxprom = zext i32 %add to i64
  %arrayidx = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom
  store i32 %la, i32* %arrayidx, align 4
  %add1 = add i32 %0, 1025
  %idxprom2 = zext i32 %add1 to i64
  %arrayidx3 = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom2
  store i32 %pa, i32* %arrayidx3, align 4
  %inc = add i32 %0, 1
  store i32 %inc, i32* @ptr_delta_buf, align 4
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @create_one_delta_chkpt(i32 %flag) local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @ipa_delta, align 4
  %cmp = icmp eq i32 %0, 512
  br i1 %cmp, label %if.then, label %entry.if.end_crit_edge

entry.if.end_crit_edge:                           ; preds = %entry
  %.pre = load i32, i32* @pba_delta, align 4
  br label %if.end

if.then:                                          ; preds = %entry
  store i32 0, i32* @ipa_delta, align 4
  %1 = load i32, i32* @pba_delta, align 4
  %inc = add i32 %1, 1
  store i32 %inc, i32* @pba_delta, align 4
  br label %if.end

if.end:                                           ; preds = %entry.if.end_crit_edge, %if.then
  %2 = phi i32 [ %0, %entry.if.end_crit_edge ], [ 0, %if.then ]
  %3 = phi i32 [ %.pre, %entry.if.end_crit_edge ], [ %inc, %if.then ]
  store i32 %flag, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), align 16
  tail call void @flash_program(i32 %3, i32 %2, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), i32 1) #9
  %4 = load i32, i32* @ipa_delta, align 4
  %inc1 = add i32 %4, 1
  store i32 %inc1, i32* @ipa_delta, align 4
  ret void
}

; Function Attrs: nounwind
define dso_local void @delete_all_delta_chkpts() local_unnamed_addr #3 {
entry:
  tail call void @flash_erase(i32 0, i32 1) #9
  tail call void @flash_erase_bulk(i32 1, i32 63) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), align 16
  tail call void @flash_program(i32 0, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), i32 1) #9
  store i32 1, i32* @ipa_delta, align 4
  store i32 0, i32* @pba_delta, align 4
  ret void
}

declare dso_local void @flash_erase_bulk(i32, i32) local_unnamed_addr #4

declare dso_local void @flash_sync() local_unnamed_addr #4

; Function Attrs: nofree norecurse nounwind
define dso_local void @reset_delta_buf() local_unnamed_addr #2 {
entry:
  store i32 0, i32* @ptr_delta_buf, align 4
  store i64 2, i64* @idx, align 8
  tail call void @invalidate_delta_buf_loop() #9
  ret void
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @delta_chkpt_region_almost_full() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @pba_delta, align 4
  %cmp = icmp ugt i32 %0, 61
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @delta_chkpt_buf_full() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @ptr_delta_buf, align 4
  %cmp = icmp eq i32 %0, 1023
  %conv = zext i1 %cmp to i32
  ret i32 %conv
}

; Function Attrs: nounwind
define dso_local void @create_full_chkpt() local_unnamed_addr #3 {
entry:
  %0 = load i32, i32* @ptr_full, align 4
  %cmp = icmp eq i32 %0, 0
  %cond = select i1 %cmp, i32 64, i32 66
  tail call void @flash_program_bulk(i32 %cond, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), align 16
  %add = or i32 %cond, 1
  tail call void @flash_program(i32 %add, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), i32 1) #9
  ret void
}

declare dso_local void @flash_program_bulk(i32, i32, i32*) local_unnamed_addr #4

; Function Attrs: nounwind
define dso_local void @delete_full_chkpt() local_unnamed_addr #3 {
entry:
  %0 = load i32, i32* @ptr_full, align 4
  %cmp = icmp eq i32 %0, 0
  %cond = select i1 %cmp, i32 64, i32 66
  %add = or i32 %cond, 1
  tail call void @flash_erase(i32 %add, i32 1) #9
  tail call void @flash_erase_bulk(i32 %cond, i32 1) #9
  ret void
}

; Function Attrs: nounwind
define dso_local void @apply_full_chkpt() local_unnamed_addr #3 {
entry:
  %0 = load i32, i32* @ptr_full, align 4
  %cmp = icmp eq i32 %0, 0
  %cond = select i1 %cmp, i32 64, i32 66
  tail call void @flash_read_bulk(i32 %cond, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  ret void
}

declare dso_local void @flash_read_bulk(i32, i32, i32*) local_unnamed_addr #4

; Function Attrs: nounwind
define dso_local void @find_committed_full_chkpt() local_unnamed_addr #3 {
entry:
  tail call void @flash_read(i32 65, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  %0 = load i32, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), align 16
  %cmp = icmp ne i32 %0, 0
  %cond = zext i1 %cmp to i32
  store i32 %cond, i32* @ptr_full, align 4
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @toggle_full_chkpt() local_unnamed_addr #2 {
entry:
  %0 = load i32, i32* @ptr_full, align 4
  %add = and i32 %0, 1
  %rem = xor i32 %add, 1
  store i32 %rem, i32* @ptr_full, align 4
  ret void
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @get_active_psa() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @pba_active, align 4
  %mul = shl i32 %0, 9
  %1 = load i32, i32* @ipa_active, align 4
  %add = add i32 %mul, %1
  %mul1 = shl i32 %add, 1
  %2 = load i32, i32* @isa_active, align 4
  %add2 = add i32 %mul1, %2
  ret i32 %add2
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @get_victim_psa() local_unnamed_addr #5 {
entry:
  %0 = load i32, i32* @pba_gc, align 4
  %mul = shl i32 %0, 9
  %1 = load i32, i32* @ipa_gc, align 4
  %add = add i32 %mul, %1
  %mul1 = shl i32 %add, 1
  %2 = load i32, i32* @isa_gc, align 4
  %add2 = add i32 %mul1, %2
  ret i32 %add2
}

; Function Attrs: noinline nounwind
define dso_local void @create_one_delta_chkpt_when_delta_buf_full() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @ptr_delta_buf, align 4
  %cmp.i = icmp eq i32 %0, 1023
  br i1 %cmp.i, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  tail call void @create_one_delta_chkpt(i32 1) #8
  store i32 0, i32* @ptr_delta_buf, align 4
  store i64 2, i64* @idx, align 8
  tail call void @invalidate_delta_buf_loop() #9
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @persist_merge_buffer_when_full() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @isa_active, align 4
  %cmp.i = icmp eq i32 %0, 2
  br i1 %cmp.i, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  tail call void @persist_merge_buffer() #8
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @make_one_erasable_block_free_when_free_blklist_empty() local_unnamed_addr #7 {
entry:
  %0 = load i64, i64* @usable, align 8
  %1 = load i64, i64* @erasable, align 8
  %cmp.i = icmp eq i64 %0, %1
  br i1 %cmp.i, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %2 = load i32, i32* %arrayidx.i, align 4
  tail call void @flash_erase(i32 %2, i32 0) #9
  %3 = load i64, i64* @erasable, align 8
  %cmp.i1 = icmp eq i64 %3, 1535
  %add.i = add i64 %3, 1
  %cond.i = select i1 %cmp.i1, i64 0, i64 %add.i
  store i64 %cond.i, i64* @erasable, align 8
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: nounwind
define dso_local void @make_one_erasable_block_unless_erasable_blklist_empty() local_unnamed_addr #3 {
entry:
  %0 = load i64, i64* @erasable, align 8
  %1 = load i64, i64* @invalid, align 8
  %cmp.i = icmp eq i64 %0, %1
  br i1 %cmp.i, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %2 = load i32, i32* %arrayidx.i, align 4
  tail call void @flash_erase(i32 %2, i32 0) #9
  %3 = load i64, i64* @erasable, align 8
  %cmp.i1 = icmp eq i64 %3, 1535
  %add.i = add i64 %3, 1
  %cond.i = select i1 %cmp.i1, i64 0, i64 %add.i
  store i64 %cond.i, i64* @erasable, align 8
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_read(i32 %lsa, i32* %data) local_unnamed_addr #3 {
entry:
  %cmp = icmp ugt i32 %lsa, 1048574
  br i1 %cmp, label %return, label %if.end

if.end:                                           ; preds = %entry
  %0 = load i32, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 1), align 4
  %cmp1 = icmp eq i32 %0, %lsa
  br i1 %cmp1, label %if.then2, label %if.end3

if.then2:                                         ; preds = %if.end
  %call = tail call i8* @memcpy32(i32* %data, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_merge, i64 0, i64 1024), i64 1024) #8
  br label %return

if.end3:                                          ; preds = %if.end
  %1 = load i32, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 0), align 4
  %cmp4 = icmp eq i32 %1, %lsa
  br i1 %cmp4, label %if.then5, label %if.end7

if.then5:                                         ; preds = %if.end3
  %call6 = tail call i8* @memcpy32(i32* %data, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_merge, i64 0, i64 0), i64 1024) #8
  br label %return

if.end7:                                          ; preds = %if.end3
  %idxprom = zext i32 %lsa to i64
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  %2 = load i32, i32* %arrayidx, align 4
  %div = lshr i32 %2, 10
  %and = lshr i32 %2, 1
  %div10 = and i32 %and, 511
  tail call void @flash_read(i32 %div, i32 %div10, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_read, i64 0, i64 0)) #9
  %and11 = shl i32 %2, 10
  %mul = and i32 %and11, 1024
  %idxprom12 = zext i32 %mul to i64
  %arrayidx13 = getelementptr inbounds [2048 x i32], [2048 x i32]* @buf_read, i64 0, i64 %idxprom12
  %call14 = tail call i8* @memcpy32(i32* %data, i32* nonnull %arrayidx13, i64 1024) #8
  br label %return

return:                                           ; preds = %entry, %if.end7, %if.then5, %if.then2
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_write(i32 %lsa, i32* nocapture readonly %data) local_unnamed_addr #3 {
entry:
  %cmp = icmp ugt i32 %lsa, 1048574
  %0 = load i32, i32* @wcnt, align 4
  %cmp1 = icmp ugt i32 %0, 2047
  %or.cond = or i1 %cmp, %cmp1
  br i1 %or.cond, label %return, label %if.end

if.end:                                           ; preds = %entry
  tail call void @make_one_erasable_block_free_when_free_blklist_empty() #8
  tail call void @persist_merge_buffer_when_full() #8
  %idxprom = zext i32 %lsa to i64
  %arrayidx = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %idxprom2 = zext i32 %1 to i64
  %arrayidx3 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom2
  store i32 1048575, i32* %arrayidx3, align 4
  %div = lshr i32 %1, 10
  %idxprom4 = zext i32 %div to i64
  %arrayidx5 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom4
  %2 = load i16, i16* %arrayidx5, align 2
  %dec = add i16 %2, -1
  store i16 %dec, i16* %arrayidx5, align 2
  %3 = load i32, i32* @pba_active, align 4
  %mul.i = shl i32 %3, 9
  %4 = load i32, i32* @ipa_active, align 4
  %add.i = add i32 %mul.i, %4
  %mul1.i = shl i32 %add.i, 1
  %5 = load i32, i32* @isa_active, align 4
  %add2.i = add i32 %mul1.i, %5
  store i32 %add2.i, i32* %arrayidx, align 4
  %idxprom8 = zext i32 %add2.i to i64
  %arrayidx9 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom8
  store i32 %lsa, i32* %arrayidx9, align 4
  %div12 = lshr i32 %add2.i, 10
  %idxprom13 = zext i32 %div12 to i64
  %arrayidx14 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom13
  %6 = load i16, i16* %arrayidx14, align 2
  %inc = add i16 %6, 1
  store i16 %inc, i16* %arrayidx14, align 2
  %7 = load i32, i32* @lsa_gc, align 4
  %cmp15 = icmp eq i32 %7, %lsa
  %cond = select i1 %cmp15, i32 1048575, i32 %7
  store i32 %cond, i32* @lsa_gc, align 4
  tail call void @copy_data_to_merge_buf(i32 %lsa, i32* %data) #8
  tail call void @create_one_delta_chkpt_when_delta_buf_full() #8
  %8 = load i32, i32* @ptr_delta_buf, align 4
  %add.i29 = add i32 %8, 2
  %idxprom.i = zext i32 %add.i29 to i64
  %arrayidx.i = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom.i
  store i32 %lsa, i32* %arrayidx.i, align 4
  %add1.i = add i32 %8, 1025
  %idxprom2.i = zext i32 %add1.i to i64
  %arrayidx3.i = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom2.i
  store i32 %add2.i, i32* %arrayidx3.i, align 4
  %inc.i = add i32 %8, 1
  store i32 %inc.i, i32* @ptr_delta_buf, align 4
  %9 = load i32, i32* @wcnt, align 4
  %inc16 = add i32 %9, 1
  store i32 %inc16, i32* @wcnt, align 4
  br label %return

return:                                           ; preds = %entry, %if.end
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @persist_merge_buffer_unless_empty() local_unnamed_addr #7 {
entry:
  %0 = load i32, i32* @isa_active, align 4
  %cmp.i = icmp eq i32 %0, 0
  br i1 %cmp.i, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  tail call void @persist_merge_buffer() #8
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @ftl_flush_precond_holds() local_unnamed_addr #5 {
entry:
  %0 = load i64, i64* @usable, align 8
  %1 = load i64, i64* @used, align 8
  %cmp = icmp ult i64 %1, %0
  %add = add i64 %1, 1536
  %.pn = select i1 %cmp, i64 %add, i64 %1
  %cond = sub i64 %.pn, %0
  %conv = trunc i64 %cond to i32
  %cmp2 = icmp ugt i32 %conv, 35
  %conv3 = zext i1 %cmp2 to i32
  ret i32 %conv3
}

; Function Attrs: nounwind
define dso_local void @ftl_flush() local_unnamed_addr #3 {
entry:
  tail call void @check_sufficient_ready_blocks() #8
  tail call void @make_one_erasable_block_free_when_free_blklist_empty() #8
  tail call void @persist_merge_buffer_unless_empty() #8
  tail call void @flash_sync() #9
  tail call void @create_one_delta_chkpt(i32 0) #8
  store i32 0, i32* @ptr_delta_buf, align 4
  store i64 2, i64* @idx, align 8
  tail call void @invalidate_delta_buf_loop() #9
  %0 = load i32, i32* @pba_delta, align 4
  %cmp.i = icmp ult i32 %0, 62
  br i1 %cmp.i, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  %1 = load i32, i32* @ptr_full, align 4
  %cmp.i1 = icmp eq i32 %1, 0
  %cond.i = select i1 %cmp.i1, i32 64, i32 66
  tail call void @flash_program_bulk(i32 %cond.i, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), align 16
  %add.i = or i32 %cond.i, 1
  tail call void @flash_program(i32 %add.i, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), i32 1) #9
  %2 = load i32, i32* @ptr_full, align 4
  %add.i2 = and i32 %2, 1
  %rem.i = xor i32 %add.i2, 1
  store i32 %rem.i, i32* @ptr_full, align 4
  %cmp.i3 = icmp eq i32 %rem.i, 0
  %cond.i4 = select i1 %cmp.i3, i32 64, i32 66
  %add.i5 = or i32 %cond.i4, 1
  tail call void @flash_erase(i32 %add.i5, i32 1) #9
  tail call void @flash_erase_bulk(i32 %cond.i4, i32 1) #9
  tail call void @flash_erase(i32 0, i32 1) #9
  tail call void @flash_erase_bulk(i32 1, i32 63) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), align 16
  tail call void @flash_program(i32 0, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), i32 1) #9
  store i32 1, i32* @ipa_delta, align 4
  store i32 0, i32* @pba_delta, align 4
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  %3 = load i64, i64* @used, align 8
  store i64 %3, i64* @invalid, align 8
  store i32 0, i32* @gcprog, align 4
  store i32 0, i32* @wcnt, align 4
  ret void
}

; Function Attrs: norecurse nounwind readonly
define dso_local i32 @reach_gc_threshold() local_unnamed_addr #5 {
entry:
  %0 = load i64, i64* @used, align 8
  %1 = load i64, i64* @active, align 8
  %cmp = icmp ult i64 %1, %0
  %add = add i64 %1, 1536
  %.pn = select i1 %cmp, i64 %add, i64 %1
  %cond = sub i64 %.pn, %0
  %cmp2 = icmp ugt i64 %cond, 1399
  %conv = zext i1 %cmp2 to i32
  ret i32 %conv
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @find_index_of_victim_block_body() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %arrayidx = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx, align 4
  %idxprom = zext i32 %1 to i64
  %arrayidx1 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom
  %2 = load i16, i16* %arrayidx1, align 2
  %3 = load i16, i16* @min_vcnt, align 2
  %cmp = icmp ult i16 %2, %3
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  store i64 %0, i64* @idx_victim, align 8
  store i16 %2, i16* @min_vcnt, align 2
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  %cmp7 = icmp eq i64 %0, 1535
  %add = add i64 %0, 1
  %cond = select i1 %cmp7, i64 0, i64 %add
  store i64 %cond, i64* @idx, align 8
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind
define dso_local void @find_index_of_victim_block_loop() local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* @idx, align 8
  %1 = load i64, i64* @active, align 8
  %cmp1 = icmp eq i64 %0, %1
  br i1 %cmp1, label %while.end, label %while.body

while.body:                                       ; preds = %entry, %while.body
  tail call void @find_index_of_victim_block_body() #8
  %2 = load i64, i64* @idx, align 8
  %3 = load i64, i64* @active, align 8
  %cmp = icmp eq i64 %2, %3
  br i1 %cmp, label %while.end, label %while.body

while.end:                                        ; preds = %while.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @swap_victim_block_to_head() local_unnamed_addr #2 {
entry:
  %0 = load i64, i64* @used, align 8
  store i64 %0, i64* @idx, align 8
  store i64 %0, i64* @idx_victim, align 8
  %arrayidx = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx, align 4
  %idxprom = zext i32 %1 to i64
  %arrayidx1 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom
  %2 = load i16, i16* %arrayidx1, align 2
  store i16 %2, i16* @min_vcnt, align 2
  tail call void @find_index_of_victim_block_loop() #8
  %3 = load i64, i64* @idx_victim, align 8
  %arrayidx2 = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %3
  %4 = load i32, i32* %arrayidx2, align 4
  %5 = load i64, i64* @used, align 8
  %arrayidx3 = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %5
  %6 = load i32, i32* %arrayidx3, align 4
  store i32 %6, i32* %arrayidx2, align 4
  store i32 %4, i32* %arrayidx3, align 4
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @choose_victim_block() local_unnamed_addr #2 {
entry:
  %0 = load i64, i64* @used, align 8
  store i64 %0, i64* @idx, align 8
  store i64 %0, i64* @idx_victim, align 8
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %1 = load i32, i32* %arrayidx.i, align 4
  %idxprom.i = zext i32 %1 to i64
  %arrayidx1.i = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom.i
  %2 = load i16, i16* %arrayidx1.i, align 2
  store i16 %2, i16* @min_vcnt, align 2
  tail call void @find_index_of_victim_block_loop() #9
  %3 = load i64, i64* @idx_victim, align 8
  %arrayidx2.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %3
  %4 = load i32, i32* %arrayidx2.i, align 4
  %5 = load i64, i64* @used, align 8
  %arrayidx3.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %5
  %6 = load i32, i32* %arrayidx3.i, align 4
  store i32 %6, i32* %arrayidx2.i, align 4
  store i32 %4, i32* %arrayidx3.i, align 4
  store i32 %4, i32* @pba_gc, align 4
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @make_victim_block_invalid() local_unnamed_addr #2 {
entry:
  %0 = load i64, i64* @used, align 8
  %cmp = icmp eq i64 %0, 1535
  %add = add i64 %0, 1
  %cond = select i1 %cmp, i64 0, i64 %add
  store i64 %cond, i64* @used, align 8
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_gc_copy() local_unnamed_addr #3 {
entry:
  %0 = load i32, i32* @enable_gc, align 4
  %tobool = icmp eq i32 %0, 0
  br i1 %tobool, label %land.lhs.true, label %if.end8

land.lhs.true:                                    ; preds = %entry
  %1 = load i64, i64* @used, align 8
  %2 = load i64, i64* @active, align 8
  %cmp.i = icmp ult i64 %2, %1
  %add.i = add i64 %2, 1536
  %.pn.i = select i1 %cmp.i, i64 %add.i, i64 %2
  %cond.i = sub i64 %.pn.i, %1
  %cmp2.i = icmp ult i64 %cond.i, 1400
  br i1 %cmp2.i, label %return, label %if.then6

if.then6:                                         ; preds = %land.lhs.true
  store i32 0, i32* @ipa_gc, align 4
  store i32 0, i32* @isa_gc, align 4
  store i32 1, i32* @enable_gc, align 4
  store i64 %1, i64* @idx, align 8
  store i64 %1, i64* @idx_victim, align 8
  %arrayidx.i.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %1
  %3 = load i32, i32* %arrayidx.i.i, align 4
  %idxprom.i.i = zext i32 %3 to i64
  %arrayidx1.i.i = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom.i.i
  %4 = load i16, i16* %arrayidx1.i.i, align 2
  store i16 %4, i16* @min_vcnt, align 2
  tail call void @find_index_of_victim_block_loop() #9
  %5 = load i64, i64* @idx_victim, align 8
  %arrayidx2.i.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %5
  %6 = load i32, i32* %arrayidx2.i.i, align 4
  %7 = load i64, i64* @used, align 8
  %arrayidx3.i.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %7
  %8 = load i32, i32* %arrayidx3.i.i, align 4
  store i32 %8, i32* %arrayidx2.i.i, align 4
  store i32 %6, i32* %arrayidx3.i.i, align 4
  store i32 %6, i32* @pba_gc, align 4
  %mul.i61 = shl i32 %6, 9
  %9 = load i32, i32* @ipa_gc, align 4
  %add.i62 = add i32 %9, %mul.i61
  %mul1.i63 = shl i32 %add.i62, 1
  %10 = load i32, i32* @isa_gc, align 4
  %add2.i64 = add i32 %mul1.i63, %10
  %idxprom = zext i32 %add2.i64 to i64
  %arrayidx = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom
  %11 = load i32, i32* %arrayidx, align 4
  store i32 %11, i32* @lsa_gc, align 4
  br label %return

if.end8:                                          ; preds = %entry
  %12 = load i32, i32* @gcprog, align 4
  %cmp = icmp ugt i32 %12, 32767
  br i1 %cmp, label %return, label %if.end10

if.end10:                                         ; preds = %if.end8
  %13 = load i32, i32* @lsa_gc, align 4
  %cmp11 = icmp ult i32 %13, 1048575
  br i1 %cmp11, label %if.then12, label %if.end32

if.then12:                                        ; preds = %if.end10
  %14 = load i32, i32* @pba_gc, align 4
  %15 = load i32, i32* @ipa_gc, align 4
  tail call void @flash_read(i32 %14, i32 %15, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_gc, i64 0, i64 0)) #9
  tail call void @make_one_erasable_block_free_when_free_blklist_empty() #8
  tail call void @persist_merge_buffer_when_full() #8
  %16 = load i32, i32* @lsa_gc, align 4
  %idxprom13 = zext i32 %16 to i64
  %arrayidx14 = getelementptr inbounds [1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 %idxprom13
  %17 = load i32, i32* %arrayidx14, align 4
  %idxprom15 = zext i32 %17 to i64
  %arrayidx16 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom15
  store i32 1048575, i32* %arrayidx16, align 4
  %div = lshr i32 %17, 10
  %idxprom17 = zext i32 %div to i64
  %arrayidx18 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom17
  %18 = load i16, i16* %arrayidx18, align 2
  %dec = add i16 %18, -1
  store i16 %dec, i16* %arrayidx18, align 2
  %19 = load i32, i32* @pba_active, align 4
  %mul.i65 = shl i32 %19, 9
  %20 = load i32, i32* @ipa_active, align 4
  %add.i66 = add i32 %mul.i65, %20
  %mul1.i67 = shl i32 %add.i66, 1
  %21 = load i32, i32* @isa_active, align 4
  %add2.i68 = add i32 %mul1.i67, %21
  store i32 %add2.i68, i32* %arrayidx14, align 4
  %idxprom22 = zext i32 %add2.i68 to i64
  %arrayidx23 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom22
  store i32 %16, i32* %arrayidx23, align 4
  %div26 = lshr i32 %add2.i68, 10
  %idxprom27 = zext i32 %div26 to i64
  %arrayidx28 = getelementptr inbounds [1605 x i16], [1605 x i16]* @vcnts, i64 0, i64 %idxprom27
  %22 = load i16, i16* %arrayidx28, align 2
  %inc = add i16 %22, 1
  store i16 %inc, i16* %arrayidx28, align 2
  %23 = load i32, i32* @isa_gc, align 4
  %mul = shl i32 %23, 10
  %idxprom29 = zext i32 %mul to i64
  %arrayidx30 = getelementptr inbounds [2048 x i32], [2048 x i32]* @buf_gc, i64 0, i64 %idxprom29
  tail call void @copy_data_to_merge_buf(i32 %16, i32* nonnull %arrayidx30) #8
  tail call void @create_one_delta_chkpt_when_delta_buf_full() #8
  %24 = load i32, i32* @lsa_gc, align 4
  %25 = load i32, i32* @ptr_delta_buf, align 4
  %add.i54 = add i32 %25, 2
  %idxprom.i = zext i32 %add.i54 to i64
  %arrayidx.i = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom.i
  store i32 %24, i32* %arrayidx.i, align 4
  %add1.i = add i32 %25, 1025
  %idxprom2.i = zext i32 %add1.i to i64
  %arrayidx3.i = getelementptr inbounds [2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 %idxprom2.i
  store i32 %add2.i68, i32* %arrayidx3.i, align 4
  %inc.i = add i32 %25, 1
  store i32 %inc.i, i32* @ptr_delta_buf, align 4
  %26 = load i32, i32* @gcprog, align 4
  %inc31 = add i32 %26, 1
  store i32 %inc31, i32* @gcprog, align 4
  br label %if.end32

if.end32:                                         ; preds = %if.then12, %if.end10
  %27 = load i32, i32* @isa_gc, align 4
  %inc33 = add i32 %27, 1
  store i32 %inc33, i32* @isa_gc, align 4
  %cmp34 = icmp eq i32 %inc33, 2
  br i1 %cmp34, label %if.then35, label %if.end32.if.end40_crit_edge

if.end32.if.end40_crit_edge:                      ; preds = %if.end32
  %.pre = load i32, i32* @ipa_gc, align 4
  br label %if.end40

if.then35:                                        ; preds = %if.end32
  store i32 0, i32* @isa_gc, align 4
  %28 = load i32, i32* @ipa_gc, align 4
  %inc36 = add i32 %28, 1
  store i32 %inc36, i32* @ipa_gc, align 4
  %cmp37 = icmp eq i32 %inc36, 512
  br i1 %cmp37, label %if.then38, label %if.end40

if.then38:                                        ; preds = %if.then35
  %29 = load i64, i64* @used, align 8
  %cmp.i51 = icmp eq i64 %29, 1535
  %add.i52 = add i64 %29, 1
  %cond.i53 = select i1 %cmp.i51, i64 0, i64 %add.i52
  store i64 %cond.i53, i64* @used, align 8
  store i32 0, i32* @ipa_gc, align 4
  store i32 0, i32* @enable_gc, align 4
  br label %if.end40

if.end40:                                         ; preds = %if.end32.if.end40_crit_edge, %if.then35, %if.then38
  %30 = phi i32 [ %inc33, %if.end32.if.end40_crit_edge ], [ 0, %if.then35 ], [ 0, %if.then38 ]
  %31 = phi i32 [ %.pre, %if.end32.if.end40_crit_edge ], [ %inc36, %if.then35 ], [ 0, %if.then38 ]
  %32 = load i32, i32* @pba_gc, align 4
  %mul.i = shl i32 %32, 9
  %add.i50 = add i32 %mul.i, %31
  %mul1.i = shl i32 %add.i50, 1
  %add2.i = add i32 %mul1.i, %30
  %idxprom42 = zext i32 %add2.i to i64
  %arrayidx43 = getelementptr inbounds [1642497 x i32], [1642497 x i32]* @p2l, i64 0, i64 %idxprom42
  %33 = load i32, i32* %arrayidx43, align 4
  store i32 %33, i32* @lsa_gc, align 4
  br label %return

return:                                           ; preds = %land.lhs.true, %if.end8, %if.end40, %if.then6
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_gc_erase() local_unnamed_addr #3 {
entry:
  %0 = load i64, i64* @erasable, align 8
  %1 = load i64, i64* @invalid, align 8
  %cmp.i.i = icmp eq i64 %0, %1
  br i1 %cmp.i.i, label %make_one_erasable_block_unless_erasable_blklist_empty.exit, label %if.then.i

if.then.i:                                        ; preds = %entry
  %arrayidx.i.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %0
  %2 = load i32, i32* %arrayidx.i.i, align 4
  tail call void @flash_erase(i32 %2, i32 0) #9
  %3 = load i64, i64* @erasable, align 8
  %cmp.i1.i = icmp eq i64 %3, 1535
  %add.i.i = add i64 %3, 1
  %cond.i.i = select i1 %cmp.i1.i, i64 0, i64 %add.i.i
  store i64 %cond.i.i, i64* @erasable, align 8
  br label %make_one_erasable_block_unless_erasable_blklist_empty.exit

make_one_erasable_block_unless_erasable_blklist_empty.exit: ; preds = %entry, %if.then.i
  ret void
}

; Function Attrs: noinline nounwind
define dso_local void @reset_committed_point_when_first_delta_page_erased() local_unnamed_addr #7 {
entry:
  tail call void @flash_read(i32 0, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  %0 = load i32, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), align 16
  %1 = icmp ult i32 %0, 2
  br i1 %1, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  store i32 0, i32* @pba_committed, align 4
  store i32 0, i32* @ipa_committed, align 4
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @reconstruct_p2l() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  tail call void @invalidate_p2l_loop() #9
  store i64 0, i64* @idx, align 8
  tail call void @remap_valid_sectors_loop() #9
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local void @reconstruct_vcnts() local_unnamed_addr #2 {
entry:
  store i64 0, i64* @idx, align 8
  tail call void @reset_vcnts_loop() #9
  store i32 0, i32* @sectid, align 4
  tail call void @count_valid_sectors_loop() #9
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_recovery() local_unnamed_addr #3 {
entry:
  tail call void @flash_read(i32 65, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0)) #9
  %0 = load i32, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), align 16
  %cmp.i = icmp ne i32 %0, 0
  %cond.i = zext i1 %cmp.i to i32
  store i32 %cond.i, i32* @ptr_full, align 4
  %cond.i2 = select i1 %cmp.i, i32 66, i32 64
  tail call void @flash_read_bulk(i32 %cond.i2, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  store i32 0, i32* @pba_committed, align 4
  store i32 0, i32* @ipa_committed, align 4
  store i32 0, i32* @blkid, align 4
  store i32 0, i32* @pgid, align 4
  tail call void @find_last_committed_delta_chkpt_loop() #9
  tail call void @reset_committed_point_when_first_delta_page_erased() #8
  store i32 0, i32* @blkid, align 4
  store i32 0, i32* @pgid, align 4
  store i64 0, i64* @idx, align 8
  tail call void @apply_delta_chkpt_loop() #9
  store i32 1642496, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 1048575), align 4
  tail call void @flash_sync() #9
  store i32 0, i32* @ptr_delta_buf, align 4
  store i64 2, i64* @idx, align 8
  tail call void @invalidate_delta_buf_loop() #9
  %1 = load i32, i32* @ptr_full, align 4
  %add.i = and i32 %1, 1
  %rem.i = xor i32 %add.i, 1
  store i32 %rem.i, i32* @ptr_full, align 4
  %cmp.i3 = icmp eq i32 %rem.i, 0
  %cond.i4 = select i1 %cmp.i3, i32 64, i32 66
  %add.i5 = or i32 %cond.i4, 1
  tail call void @flash_erase(i32 %add.i5, i32 1) #9
  tail call void @flash_erase_bulk(i32 %cond.i4, i32 1) #9
  %2 = load i32, i32* @ptr_full, align 4
  %cmp.i6 = icmp eq i32 %2, 0
  %cond.i7 = select i1 %cmp.i6, i32 64, i32 66
  tail call void @flash_program_bulk(i32 %cond.i7, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), align 16
  %add.i8 = or i32 %cond.i7, 1
  tail call void @flash_program(i32 %add.i8, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), i32 1) #9
  %3 = load i32, i32* @ptr_full, align 4
  %add.i9 = and i32 %3, 1
  %rem.i10 = xor i32 %add.i9, 1
  store i32 %rem.i10, i32* @ptr_full, align 4
  %cmp.i11 = icmp eq i32 %rem.i10, 0
  %cond.i12 = select i1 %cmp.i11, i32 64, i32 66
  %add.i13 = or i32 %cond.i12, 1
  tail call void @flash_erase(i32 %add.i13, i32 1) #9
  tail call void @flash_erase_bulk(i32 %cond.i12, i32 1) #9
  tail call void @flash_erase(i32 0, i32 1) #9
  tail call void @flash_erase_bulk(i32 1, i32 63) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), align 16
  tail call void @flash_program(i32 0, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @delta_buf, i64 0, i64 0), i32 1) #9
  store i32 1, i32* @ipa_delta, align 4
  store i32 0, i32* @pba_delta, align 4
  store i64 0, i64* @idx, align 8
  tail call void @invalidate_p2l_loop() #9
  store i64 0, i64* @idx, align 8
  tail call void @remap_valid_sectors_loop() #9
  store i64 0, i64* @idx, align 8
  tail call void @reset_vcnts_loop() #9
  store i32 0, i32* @sectid, align 4
  tail call void @count_valid_sectors_loop() #9
  store i64 0, i64* @erasable, align 8
  store i64 0, i64* @invalid, align 8
  store i64 0, i64* @used, align 8
  %call.i = tail call i8* @memset(i8* getelementptr inbounds ([1537 x i8], [1537 x i8]* @is_used, i64 0, i64 0), i32 0, i64 1537) #9
  store i32 0, i32* @sectid, align 4
  tail call void @identify_used_blocks_loop() #9
  store i64 0, i64* @idx, align 8
  store i32 68, i32* @blkid, align 4
  tail call void @categorize_used_and_erasable_blocks_loop() #9
  %4 = load i64, i64* @erasable, align 8
  store i64 %4, i64* @usable, align 8
  tail call void @check_sufficient_avail_blocks() #8
  %5 = load i64, i64* @erasable, align 8
  %arrayidx.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %5
  %6 = load i32, i32* %arrayidx.i, align 4
  tail call void @flash_erase(i32 %6, i32 0) #9
  %7 = load i64, i64* @erasable, align 8
  %cmp.i14 = icmp eq i64 %7, 1535
  %add.i15 = add i64 %7, 1
  %cond.i16 = select i1 %cmp.i14, i64 0, i64 %add.i15
  store i64 %cond.i16, i64* @erasable, align 8
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 0), align 4
  store i32 1048575, i32* getelementptr inbounds ([2 x i32], [2 x i32]* @lsas_merge, i64 0, i64 1), align 4
  store i32 0, i32* @isa_active, align 4
  store i32 0, i32* @ipa_active, align 4
  %8 = load i64, i64* @usable, align 8
  %arrayidx.i.i = getelementptr inbounds [1536 x i32], [1536 x i32]* @blk_list, i64 0, i64 %8
  %9 = load i32, i32* %arrayidx.i.i, align 4
  store i32 %9, i32* @pba_active, align 4
  store i64 %8, i64* @active, align 8
  %cmp.i.i = icmp eq i64 %8, 1535
  %add.i.i = add i64 %8, 1
  %cond.i.i = select i1 %cmp.i.i, i64 0, i64 %add.i.i
  store i64 %cond.i.i, i64* @usable, align 8
  store i32 0, i32* @enable_gc, align 4
  store i32 0, i32* @ipa_gc, align 4
  store i32 0, i32* @isa_gc, align 4
  store i32 68, i32* @pba_gc, align 4
  store i32 1048575, i32* @lsa_gc, align 4
  tail call void @check_l2p_injective() #8
  store i32 0, i32* @gcprog, align 4
  store i32 0, i32* @wcnt, align 4
  ret void
}

; Function Attrs: nounwind
define dso_local void @ftl_format() local_unnamed_addr #3 {
entry:
  tail call void @flash_erase_bulk(i32 0, i32 1605) #9
  %call = tail call i32* @memset32(i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0), i32 1642496, i64 1048576) #8
  store i32 0, i32* @ptr_full, align 4
  tail call void @flash_program_bulk(i32 64, i32 1, i32* getelementptr inbounds ([1048576 x i32], [1048576 x i32]* @l2p, i64 0, i64 0)) #9
  tail call void @flash_sync() #9
  store i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), align 16
  tail call void @flash_program(i32 65, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_commit, i64 0, i64 0), i32 1) #9
  %call1 = tail call i32* @memset32(i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), i32 -1, i64 2048) #8
  tail call void @flash_program(i32 1604, i32 0, i32* getelementptr inbounds ([2048 x i32], [2048 x i32]* @buf_tmp, i64 0, i64 0), i32 1) #9
  ret void
}

attributes #0 = { nofree noinline norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree noinline norecurse nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-builtins" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { norecurse nounwind readonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { nofree norecurse nounwind writeonly "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { noinline nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="false" "no-jump-tables"="true" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+x87,-aes,-avx,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512er,-avx512f,-avx512ifma,-avx512pf,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-f16c,-fma,-fma4,-gfni,-pclmul,-sha,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-xop,-xsave,-xsaveopt" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #8 = { nobuiltin "no-builtins" }
attributes #9 = { nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 10.0.0-4ubuntu1 "}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.unroll.disable"}
!4 = distinct !{!4, !3}
!5 = distinct !{!5, !3}
