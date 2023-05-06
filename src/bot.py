import os
import sys
import re
import hashlib
from boto3 import Session
import discord
from discord.ext import commands
from dotenv import load_dotenv
from call_polly import call_polly

# Create a client using the credentials and region defined in the default user
# section of the AWS credentials file (~/.aws/credentials).
session = Session(region_name="us-east-2")
polly = session.client("polly")

load_dotenv()
discord_token = os.environ.get('DISCORD_TOKEN')
intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix='/', intents=intents)


# @bot.command()
# async def ping(ctx):
#     await ctx.send('pong')


@bot.command()
async def speak(ctx):
    print('MESSAGE RECEIVED:')
    message = ctx.message.content
    print(message)
    # hash the message for the filename (should probably truncate this)
    message_hash = hashlib.sha1(message.encode("UTF-8")).hexdigest()
    parsed_message = re.sub(r'^\/speak', '', message)
    mp3_path = call_polly(parsed_message, message_hash, polly)
    attachment = discord.File(mp3_path, spoiler=False)
    await ctx.reply(file=attachment)

bot.run(discord_token)
