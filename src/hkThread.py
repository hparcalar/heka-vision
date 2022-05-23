import threading

class HekaThread(threading.Thread):
    def __init__(self,  *args, **kwargs):
        super(HekaThread, self).__init__(*args, **kwargs)
        self._stop_event = threading.Event()

    def stop(self):
        self._stop_event.set()

    def stopped(self):
        return self._stop_event.is_set()