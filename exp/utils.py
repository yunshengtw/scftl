import csv
import os, sys
import numpy as np
import re

"""
load_csv returns two lists of tuples: rows and cols.
Fields with empty value are filled with None.
"""
def load_csv(fpath, fillval=None, astype='float', delimiter=','):
    def _safe_to_float(val):
        try:
            return float(val)
        except:
            return val

    with open(fpath, 'r') as f:
        #print('Parsing csv file: {}'.format(fpath))
        rows = list(csv.reader(f, delimiter=delimiter))
        if astype == 'float':
            rows = [list(map(_safe_to_float, row)) for row in rows]
        n_fields = max(map(len, rows))
        for row in rows:
            if len(row) < n_fields:
                row.extend([fillval] * (n_fields - len(row)))
        rows = list(map(tuple, rows))
        cols = list(zip(*rows))
        #print('Number of rows: {}'.format(len(rows)))
        #print('Number of columns: {}'.format(len(cols)))
    return rows, cols

def save_csv(fpath, rows):
    with open(fpath, 'w') as f:
        writer = csv.writer(f, delimiter=',')
        for row in rows:
            writer.writerow(row)

def safe_scale(val, scale):
    try:
        return val * scale
    except:
        return val

