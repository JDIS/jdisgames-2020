import run_bot

from bot import MyBot
from multiprocessing import Process

secret_keys = [
    
]

if __name__ == '__main__':
    processes = []
    for key in secret_keys:
        processes.append(Process(target=run_bot.loop, args=(key,)))

    for process in processes:
        process.start()

    input("Press a key to terminate")

    for process in processes:
        process.terminate()