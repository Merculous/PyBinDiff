#!/usr/bin/env python3

import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from collections import OrderedDict
from pathlib import Path


def groupValues(values: OrderedDict) -> OrderedDict:
    new_diff = OrderedDict()

    tmp1 = ''
    tmp2 = ''

    for difference in values:
        value1 = values[difference][0]
        value2 = values[difference][1]

        to_add = '0123456789abcdef'

        if value1 in to_add and len(value1) == 1:
            value1 = '0' + value1

        tmp1 += value1

        if value2 in to_add and len(value2) == 1:
            value2 = '0' + value2

        tmp2 += value2

        if difference != 0 and difference % 8 == 0:
            tmp1_len = len(tmp1)
            tmp2_len = len(tmp2)

            if tmp1_len != tmp2_len:
                sys.stderr.write('Length of hex strings differ!\n')
                sys.exit(1)
            elif tmp1_len == 16 and tmp2_len == 16:
                new_diff[difference] = (tmp1, tmp2)

            tmp1, tmp2 = '', ''
            tmp1_len, tmp2_len = 0, 0

    return new_diff


def diff(file1: Path, file2: Path) -> None:
    if file1.is_file() and file2.is_file():
        with open(file1, 'rb') as f:
            f_data = f.read()

        with open(file2, 'rb') as ff:
            ff_data = ff.read()

        x = 1

        differences = OrderedDict()
        # equal = OrderedDict()

        for i, ii in zip(f_data, ff_data):
            if i != ii:
                differences[x] = (format(i, 'x'), format(ii, 'x'))
                x += 1
            # else:
                # equal[x] = format(i, 'x')

        differences = groupValues(differences)

        print(f'Number of byte differences: {len(differences)}')
        # print(f'Number of bytes equal: {len(equal)}')

        out = Path('diff.json')

        if out.exists():
            sys.stderr.write(f'{out.name} already exists!\n')
            sys.exit(1)
        else:
            print('Writing output to json file...')

            with open(out, 'w') as j:
                start = time.time()
                json.dump(differences, j, indent=1)
                end = time.time() - start
                print(f'Write to json took: {end:.4f} seconds')

    else:
        sys.stderr.write('Passed in arguments aren\'t files!\n')
        sys.exit(1)


def main(args: tuple) -> None:
    argc = len(args)
    if argc == 3:
        diff(Path(args[1]), Path(args[2]))
    else:
        sys.stderr.write(f'Usage: {args[0]} <file1> <file2>\n')
        sys.exit(1)


if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=2) as executor:
        executor.submit(main, tuple(sys.argv))
