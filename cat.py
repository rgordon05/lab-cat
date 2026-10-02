'''
This program prints stdin to the screen.
'''
import sys

def cat(file):
    # Read in chunks of 8192 bytes to maintain O(1) memory usage
    while True:
        data = file.read(8192)
        if not data:
            break
        sys.stdout.buffer.write(data)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for filename in sys.argv[1:]:
            with open(filename, "rb") as f:
                cat(f)
    else:
        cat(sys.stdin.buffer)
