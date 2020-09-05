from utils import *

wi_to_fig5 = {
    1       : "a",
    16      : "b",
    256     : "c",
    2048    : "d"
}

app_to_unit = {
    "SQLite"        : "txn/s",
    "smallfiles"    : "file/s",
    "largefile"     : "MB/s",
    "mailbench"     : "msg/s"
}

samples = [0, 10, 20, 30, 40, 50]
#samples = [0]

if __name__ == '__main__':
    # Figure 5
    for wr_interval in [1, 16, 256, 2048]:
        for ftl in ["pblk", "async", "sync", "scftl"]:
            print("Comparing Figure 5({}) legend = {} (unit: K IOPS)".format(wi_to_fig5[wr_interval], ftl))
            rows_gen, _ = load_csv('gen/' + ftl + '-' + str(wr_interval) + '.csv', astype='float')
            rows_ref, _ = load_csv('ref/' + ftl + '-' + str(wr_interval) + '.csv', astype='float')
            row_gen = rows_gen[0]
            row_ref = rows_ref[0]
            for s in samples:
                print("[x = {} sec] yours = {:.2f} ours = {:.2f} diff = {:.2f} ({:+.2f}%)".format(
                    s * 10, row_gen[s], row_ref[s], row_gen[s] - row_ref[s],
                    (row_gen[s] - row_ref[s]) / row_ref[s] * 100))
            print("[average] yours = {:.2f} ours = {:.2f} diff = {:.2f} ({:+.2f}%)\n".format(
                np.average(row_gen), np.average(row_ref),
                np.average(row_gen) - np.average(row_ref),
                (np.average(row_gen) - np.average(row_ref)) / np.average(row_ref) * 100))
            if wr_interval == 2048 and ftl == "async":
                tp_2048_async_gen = np.average(row_gen)
                tp_2048_async_ref = np.average(row_ref)
            if wr_interval == 2048 and ftl == "scftl":
                tp_2048_scftl_gen = np.average(row_gen)
                tp_2048_scftl_ref = np.average(row_ref)
    rtp_2048_gen = tp_2048_scftl_gen / tp_2048_async_gen * 100
    rtp_2048_ref = tp_2048_scftl_ref / tp_2048_async_ref * 100

    # Figure 6
    tp_async_gen = []
    tp_scftl_gen = []
    tp_async_ref = []
    tp_scftl_ref = []
    for i, app in enumerate(["SQLite", "smallfiles", "largefile", "mailbench"]):
        print("Comparing Figure 6 application = {} (unit: {})".format(app, app_to_unit[app]))
        rows_gen, _ = load_csv('gen/xv6.csv', astype='float')
        rows_ref, _ = load_csv('ref/xv6.csv', astype='float')
        row_gen = rows_gen[i]
        row_ref = rows_ref[i]
        for j, fs in enumerate(["xv6/async", "xv6/sync", "xv6-xlog", "xv6-group"]):
            print("[legend = {}] yours = {:.2f} ours = {:.2f} diff = {:.2f} ({:+.2f}%)".format(
                fs, row_gen[j], row_ref[j], row_gen[j] - row_ref[j],
                (row_gen[j] - row_ref[j]) / row_ref[j] * 100))
        tp_async_gen.append(row_gen[0])
        tp_async_ref.append(row_ref[0])
        tp_scftl_gen.append(row_gen[3])
        tp_scftl_ref.append(row_ref[3])
        print("")

    # Figure 7
    tp_ext4_gen = []
    tp_xv6_gen = []
    tp_ext4_ref = []
    tp_xv6_ref = []
    for i, app in enumerate(["SQLite", "smallfiles", "largefile", "mailbench"]):
        print("Comparing Figure 7 application = {} (unit: {})".format(app, app_to_unit[app]))
        rows_gen, _ = load_csv('gen/xv6-ext4.csv', astype='float')
        rows_ref, _ = load_csv('ref/xv6-ext4.csv', astype='float')
        row_gen = rows_gen[i]
        row_ref = rows_ref[i]
        for j, fs in enumerate(["ext4-metadata", "ext4-data", "xv6-group"]):
            print("[legend = {}] yours = {:.2f} ours = {:.2f} diff = {:.2f} ({:+.2f}%)".format(
                fs, row_gen[j], row_ref[j], row_gen[j] - row_ref[j],
                (row_gen[j] - row_ref[j]) / row_ref[j] * 100))
        tp_ext4_gen.append(row_gen[0])
        tp_ext4_ref.append(row_ref[0])
        tp_xv6_gen.append(row_gen[2])
        tp_xv6_ref.append(row_ref[2])
        print("")

    # Summary
    print("Key finding 1: The overhead due to snapshot consistency should be little when the write interval is large enough.")
    print("Computing the relative performance of *scftl* to *async* given write interval = 2048 (Figure 5)")
    print("yours = {:.2f}% ours = {:.2f}% diff = {:+.2f}%".format(
            rtp_2048_gen, rtp_2048_ref, rtp_2048_gen - rtp_2048_ref))
    print("")
    print("Key finding 2: SCFTL should be useful from the perspective of a file system.")
    print("Computing the relative performance of *xv6-group* to *xv6/async* (Figure 6)")
    print("[SQLite] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_scftl_gen[0] / tp_async_gen[0],
        tp_scftl_ref[0] / tp_async_ref[0],
        tp_scftl_gen[0] / tp_async_gen[0] - tp_scftl_ref[0] / tp_async_ref[0]))
    print("[smallfiles] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_scftl_gen[1] / tp_async_gen[1],
        tp_scftl_ref[1] / tp_async_ref[1],
        tp_scftl_gen[1] / tp_async_gen[1] - tp_scftl_ref[1] / tp_async_ref[1]))
    print("[largefile] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_scftl_gen[2] / tp_async_gen[2],
        tp_scftl_ref[2] / tp_async_ref[2],
        tp_scftl_gen[2] / tp_async_gen[2] - tp_scftl_ref[2] / tp_async_ref[2]))
    print("[mailbench] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_scftl_gen[3] / tp_async_gen[3],
        tp_scftl_ref[3] / tp_async_ref[3],
        tp_scftl_gen[3] / tp_async_gen[3] - tp_scftl_ref[3] / tp_async_ref[3]))
    print("")
    print("Key finding 3: The performance of xv6 + SCFTL should not be too far from that of the state-of-the-art ext4 + pblk.")
    print("Computing the relative performance of *xv6-group* to *ext4-metadata* (Figure 7)")
    print("[SQLite] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_xv6_gen[0] / tp_ext4_gen[0],
        tp_xv6_ref[0] / tp_ext4_ref[0],
        tp_xv6_gen[0] / tp_ext4_gen[0] - tp_xv6_ref[0] / tp_ext4_ref[0]))
    print("[smallfiles] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_xv6_gen[1] / tp_ext4_gen[1],
        tp_xv6_ref[1] / tp_ext4_ref[1],
        tp_xv6_gen[1] / tp_ext4_gen[1] - tp_xv6_ref[1] / tp_ext4_ref[1]))
    print("[largefile] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_xv6_gen[2] / tp_ext4_gen[2],
        tp_xv6_ref[2] / tp_ext4_ref[2],
        tp_xv6_gen[2] / tp_ext4_gen[2] - tp_xv6_ref[2] / tp_ext4_ref[2]))
    print("[mailbench] yours = {:.2f}x ours = {:.2f}x diff = {:+.2f}x".format(
        tp_xv6_gen[3] / tp_ext4_gen[3],
        tp_xv6_ref[3] / tp_ext4_ref[3],
        tp_xv6_gen[3] / tp_ext4_gen[3] - tp_xv6_ref[3] / tp_ext4_ref[3]))
