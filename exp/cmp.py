from utils import *

wi_to_fig5 = {
    1       : "a",
    16      : "b",
    256     : "c",
    2048    : "d"
}

samples = [0, 10, 20, 30, 40, 50]
#samples = [0]

if __name__ == '__main__':
    # Figure 5
    for wr_interval in [1, 16, 256, 2048]:
        for ftl in ["pblk", "async", "sync", "scftl"]:
            print("Comparing Figure 5({}) legend = {}".format(wi_to_fig5[wr_interval], ftl))
            rows_gen, _ = load_csv('gen/' + ftl + '-' + str(wr_interval) + '.csv', astype='float')
            rows_ref, _ = load_csv('ref/' + ftl + '-' + str(wr_interval) + '.csv', astype='float')
            row_gen = rows_gen[0]
            row_ref = rows_ref[0]
            for s in samples:
                print("[time = {} sec] gen = {} ref = {} diff = {} ({:+.2f}%)".format(
                    s * 10, row_gen[s], row_ref[s], row_gen[s] - row_ref[s],
                    ((row_gen[s] - row_ref[s]) / row_ref[s]) * 100))
            print("[average] gen = {} ref = {} diff = {}\n".format(
                np.average(row_gen), np.average(row_ref),
                np.average(row_gen) - np.average(row_ref)))

    # Figure 6
    for i, app in enumerate(["SQLite", "smallfile", "largefile", "mailbench"]):
        print("Comparing Figure 6 application = {}".format(app))
        rows_gen, _ = load_csv('gen/xv6.csv', astype='float')
        rows_ref, _ = load_csv('ref/xv6.csv', astype='float')
        row_gen = rows_gen[i]
        row_ref = rows_ref[i]
        for j, fs in enumerate(["xv6/async", "xv6/sync", "xv6-xlog", "xv6-group"]):
            print("[legend = {}] gen = {} ref = {} diff = {} ({:+.2f}%)".format(
                fs, row_gen[j], row_ref[j], row_gen[j] - row_ref[j],
                ((row_gen[j] - row_ref[j]) / row_ref[j]) * 100))
        print("")

    # Figure 7
    for i, app in enumerate(["SQLite", "smallfile", "largefile", "mailbench"]):
        print("Comparing Figure 7 application = {}".format(app))
        rows_gen, _ = load_csv('gen/xv6-ext4.csv', astype='float')
        rows_ref, _ = load_csv('ref/xv6-ext4.csv', astype='float')
        row_gen = rows_gen[i]
        row_ref = rows_ref[i]
        for j, fs in enumerate(["ext4-metadata", "ext4-data", "xv6-group"]):
            print("[legend = {}] gen = {} ref = {} diff = {} ({:+.2f}%)".format(
                fs, row_gen[j], row_ref[j], row_gen[j] - row_ref[j],
                ((row_gen[j] - row_ref[j]) / row_ref[j]) * 100))
        print("")

