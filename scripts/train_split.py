import os
import json
import click
import logging

import random

random.seed(1234)

def write_files(file_list, corpus_dir, split_file):

    with open(split_file, 'w') as split_file:
        for filename in file_list:
            fp = os.path.join(corpus_dir, filename)
            logging.debug(f'Reading {fp} from disk...')

            with open(fp, 'r') as f:
                split_file.write(f.read() + '\n\n')


@click.command()
@click.option("--corpus_dir", help="Path to transcripts.json")
@click.option("--output_dir", help="Path to save train, test split")
@click.option("--log_level", default="INFO", help="Log level (default: INFO)")
def main(corpus_dir, output_dir, log_level):

    # Set logger config
    logging.basicConfig(
        level=log_level, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    corpus_files = [f for f in os.listdir(corpus_dir) if f.endswith('.txt')]
    num_train = int(len(corpus_files) * 0.9)
    train_files = corpus_files[:num_train]
    test_files = corpus_files[num_train:]

    logging.info("Writing data/train.txt...")
    write_files(train_files, corpus_dir, 'data/train.txt')

    logging.info("Writing data/test.txt...")
    write_files(test_files, corpus_dir, 'data/test.txt')

    logging.info("Done!")


if __name__ == "__main__":
    main()
