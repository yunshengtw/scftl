from utils import *

def parse_sqlite(fs):
    _, cols = load_csv('raw/' + fs + '-sqlite.log', astype='float', delimiter=' ')
    col = cols[1]
    time = [col[0], col[3], col[6], col[9], col[12]]
    tp = [1000 / val for val in time]
    avg = np.average(tp)
    return avg

def parse_smallfiles(fs):
    _, cols = load_csv('raw/' + fs + '-smallfiles.log', astype='float', delimiter=' ')
    col = cols[0]
    tp_3s = [col[1], col[3], col[5], col[7], col[9]]
    tp = [val / 3 for val in tp_3s]
    avg = np.average(tp)
    return avg

def parse_largefile(fs):
    _, cols = load_csv('raw/' + fs + '-largefile.log', astype='float', delimiter=' ')
    tp_kb = cols[8]
    tp = [val / 1000 for val in tp_kb]
    avg = np.average(tp)
    return avg

def parse_mailbench(fs):
    tp_3s = []
    fpath = 'raw/' + fs + '-mailbench.log'
    with open(fpath, 'r') as f:
        for l in f:
            if re.search("messages/sec", l):
                tp_3s.append(float(l.split()[0]))
    tp = [val / 3 for val in tp_3s]
    avg = np.average(tp)
    return avg

if __name__ == '__main__':
    if not os.path.exists('gen'):
        os.mkdir('gen')

    # Figure 5
    for wr_interval in [1, 16, 256, 2048]:
        _, cols_pblk = load_csv('raw/pblk-' + str(wr_interval) + '.log', astype='float', delimiter=' ')
        y_scale_pblk = [safe_scale(val, 1/10000.0) for val in cols_pblk[-1]]
        save_csv('gen/pblk-' + str(wr_interval) + '.csv', [y_scale_pblk[1:]])
        #print(y_scale_pblk)

        _, cols_async = load_csv('raw/async-' + str(wr_interval) + '.log', astype='float', delimiter=' ')
        y_scale_async = [safe_scale(val, 1/10000.0) for val in cols_async[-1]]
        save_csv('gen/async-' + str(wr_interval) + '.csv', [y_scale_async[1:]])
        #print(y_scale_async)

        _, cols_sync = load_csv('raw/sync-' + str(wr_interval) + '.log', astype='float', delimiter=' ')
        y_scale_sync = [safe_scale(val, 1/10000.0) for val in cols_sync[-1]]
        save_csv('gen/sync-' + str(wr_interval) + '.csv', [y_scale_async[1:]])
        #print(y_scale_sync)

        _, cols_sc = load_csv('raw/scftl-' + str(wr_interval) + '.log', astype='float', delimiter=' ')
        y_scale_sc = [safe_scale(val, 1/10000.0) for val in cols_sc[-1]]
        save_csv('gen/scftl-' + str(wr_interval) + '.csv', [y_scale_async[1:]])
        #print(y_scale_sc)

    # Figure 6
    sqlite_res = [
        parse_sqlite('xv6fs'),
        parse_sqlite('xv6fs-xflush'),
        parse_sqlite('xv6fs-xlog'),
        parse_sqlite('xv6fs-xlog-gcm')
    ]
    print(sqlite_res)
    smallfiles_res = [
        parse_smallfiles('xv6fs'),
        parse_smallfiles('xv6fs-xflush'),
        parse_smallfiles('xv6fs-xlog'),
        parse_smallfiles('xv6fs-xlog-gcm')
    ]
    print(smallfiles_res)
    largefile_res = [
        parse_largefile('xv6fs'),
        parse_largefile('xv6fs-xflush'),
        parse_largefile('xv6fs-xlog'),
        parse_largefile('xv6fs-xlog-gcm')
    ]
    print(largefile_res)
    mailbench_res = [
        parse_mailbench('xv6fs'),
        parse_mailbench('xv6fs-xflush'),
        parse_mailbench('xv6fs-xlog'),
        parse_mailbench('xv6fs-xlog-gcm')
    ]
    print(mailbench_res)
    save_csv('gen/xv6.csv', [sqlite_res, smallfiles_res, largefile_res, mailbench_res])

    # Figure 7
    sqlite_res = [
        parse_sqlite('ext4-metadata'),
        parse_sqlite('ext4-data'),
        parse_sqlite('xv6fs-xlog-gcm')
    ]
    print(sqlite_res)
    smallfiles_res = [
        parse_smallfiles('ext4-metadata'),
        parse_smallfiles('ext4-data'),
        parse_smallfiles('xv6fs-xlog-gcm')
    ]
    print(smallfiles_res)
    largefile_res = [
        parse_largefile('ext4-metadata'),
        parse_largefile('ext4-data'),
        parse_largefile('xv6fs-xlog-gcm')
    ]
    print(largefile_res)
    mailbench_res = [
        parse_mailbench('ext4-metadata'),
        parse_mailbench('ext4-data'),
        parse_mailbench('xv6fs-xlog-gcm')
    ]
    print(mailbench_res)
    save_csv('gen/xv6-ext4.csv', [sqlite_res, smallfiles_res, largefile_res, mailbench_res])

