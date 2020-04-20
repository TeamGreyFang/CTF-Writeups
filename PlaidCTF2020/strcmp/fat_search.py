import struct


def parse_fat_directory_row(chunk_32):
    x = struct.unpack("<11sccchhhhhhhI",chunk_32)
    name = x[0].decode("utf-8").strip()
    entry_type = 'dir' if bin(x[1][0])[2:].zfill(8)[3] == '1' else 'file'
    location = x[7] + x[10]
    return (name,entry_type,location)

def split_chunk(string, length):
    return (string[0+i:length+i] for i in range(0, len(string), length))

def s(N):
    return ((N-2) + 521)*512

SECTOR_SIZE = 512

'''

positions = {}
dir_tree = {}

reverse_mapping = {}

already_tested = []


def read_directory(fat,sector_index):
    dir_index = sector_index
    while s(sector_index) <= len(fat):
        if (sector_index - 2) % 4 == 0:
            dir_index = sector_index
        sector_start = s(sector_index)
        sector_end = sector_start + SECTOR_SIZE
        current_sector = fat[sector_start:sector_end]
        if sector_index not in dir_tree.keys():
            dir_tree[sector_index] = []
        for chunk in split_chunk(current_sector,32):
            if chunk != b'\x00'*32:
                parsed = parse_fat_directory_row(chunk)
                parsed += (dir_index,)
                next_chunk_location = parsed[2]
                dir_tree[sector_index].append(parsed[2])
                if next_chunk_location not in reverse_mapping.keys():
                    reverse_mapping[next_chunk_location] = []
                if parsed not in reverse_mapping[next_chunk_location]:
                    reverse_mapping[next_chunk_location].append(parsed)
                positions[sector_index] = parsed
        sector_index += 1
'''        

def next_opts(fat,sector_index):
    dir_index = sector_index
    i = sector_index
    opts = []
    while s(sector_index) <= len(fat):
        if (sector_index - 2) % 4 == 0:
            dir_index = sector_index
        sector_start = s(sector_index)
        sector_end = sector_start + SECTOR_SIZE
        current_sector = fat[sector_start:sector_end]
        for chunk in split_chunk(current_sector,32):
            if chunk != b'\x00'*32:
                parsed = parse_fat_directory_row(chunk)
                parsed += (dir_index,)
                opts.append(parsed)
        sector_index += 1
        if sector_index - i == 4:
            return opts


def options_for_x(fat,start_flag=['P','C','T','F','{','W']):
    start=2
    opts = []
    for x in start_flag:
        for opt in next_opts(fat,start):
            if opt[0] == x:
                start = opt[2]
            opts.append(opt[2])
    for opt in next_opts(fat,start):
        if opt[2] not in opts:
            new_start_flag = start_flag + [opt[0]]
            print("".join(new_start_flag))
            if opt[0] != "}":
                options_for_x(fat,start_flag=new_start_flag)

'''
def print_tree(start_dir):
    flag = ""
    try:
        while True:
            nex = reverse_mapping[start_dir]
            flag += nex[0][0]
            start_dir = nex[0][3]
    except Exception as e:
        print(flag[::-1])
        return int(str(e))
''' 

def parse_fat(fat):
    # read root directory
    # read_directory(fat,2)
    # for p in positions.keys():
    #    if positions[p][0] == 'MATCH':
    #        match = positions[p]
    #        print(match)
    #        print_tree(match[3])
    options_for_x(fat)
    



with open("strcmp.fat32","rb") as f:
    parse_fat(f.read())