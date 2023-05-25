import sys
from contextlib import closing
from file_helpers import write_to_tmp_file
import boto3
from botocore.exceptions import BotoCoreError, ClientError


def call_polly(message, filename, polly, bucket_name):
    '''Call AWS Polly with the message.
    Returns the path of the mp3 file created if audio streaming was successful.

    Keyword arguments:
    message -- message to send to AWS polly
    filename -- name of the file
    polly -- an initialized AWS polly client
    bucket_name -- the name of the s3 bucket to store the mp3 files


    returns os.PathLike
    '''
    client = boto3.client('s3')
    key = f'{filename}.mp3'
    try:
        req = client.get_object(
            Bucket=bucket_name, ResponseCacheControl=f'max-age={60 * 60 * 24 * 7}', Key=key)
        mp3 = req['Body'].read()
        if mp3:
            print('Found message, returning filepath')
            return write_to_tmp_file(filename, mp3)
    except ClientError as error:
        print(error)
        print('Could not find mp3 in bucket')

    print('Sending message to Polly')
    try:
        # Request speech synthesis
        response = polly.synthesize_speech(Text=message, OutputFormat="mp3",
                                           VoiceId="Joanna")
    except (BotoCoreError, ClientError) as error:
        # The service returned an error, exit gracefully
        print(error)
        sys.exit(-1)

    # Access the audio stream from the response
    if "AudioStream" in response:
        # Note: Closing the stream is important because the service throttles on the
        # number of parallel connections. Here we are using contextlib.closing to
        # ensure the close method of the stream object will be called automatically
        # at the end of the with statement's scope.
        with closing(response["AudioStream"]) as stream:
            mp3 = stream.read()

            try:
                # Open a file for writing the output as a binary stream
                client.put_object(
                    Bucket=bucket_name,
                    Key=key,
                    Body=mp3)
                return write_to_tmp_file(filename, mp3)
            except IOError as error:
                # Could not write to file, exit gracefully
                print(error)
                sys.exit(-1)

    else:
        # The response didn't contain audio data, exit gracefully
        print("Could not stream audio")
        sys.exit(-1)
