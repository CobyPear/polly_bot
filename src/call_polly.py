"""Getting Started Example for Python 2.7+/3.3+"""
import os
import sys
from contextlib import closing
from botocore.exceptions import BotoCoreError, ClientError


def call_polly(message, filename, polly):
    '''Call AWS Polly with the message.
    Returns the path of the mp3 file created if audio streaming was successful.

    Keyword arguments:
    message -- message to send to AWS polly
    filename -- what to name the file
    polly -- an initialized AWS polly client


    returns os.PathLike
    '''

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
            output_path = os.path.join("./polly_output", f'{filename}.mp3')

            try:
                # Open a file for writing the output as a binary stream
                with open(output_path, "wb") as file:
                    file.write(stream.read())
            except IOError as error:
                # Could not write to file, exit gracefully
                print(error)
                sys.exit(-1)

    else:
        # The response didn't contain audio data, exit gracefully
        print("Could not stream audio")
        sys.exit(-1)

    return output_path
