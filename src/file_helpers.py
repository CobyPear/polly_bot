'''write file helpers'''


def write_to_tmp_file(filename, stream):
    '''Write the stream to a temp file

    Keyword arguments:
    filename -- name of the file to write
    '''
    filepath = f'/tmp/{filename}.mp3'
    try:
        with open(filepath, "wb") as file:
            file.write(stream)
            print(f'Wrote file to {filepath}')
        return filepath
    except FileExistsError as error:
        print(error)
        return filepath
