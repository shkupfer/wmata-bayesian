import argparse
import datetime
import httplib
import urllib
import os
import pytz


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--wmata_api_key', default=os.getenv('WMATA_API_KEY'))
    parser.add_argument('--timezone', default='America/New_York')
    parser.add_argument('output_dir', default='.')
    args = parser.parse_args()

    headers = {'api_key': args.wmata_api_key}
    params = urllib.urlencode({})

    while True:
        tz = pytz.timezone(args.timezone)
        tz_now = datetime.datetime.now(tz).strftime('%Y-%m-%d_%H:%M:%S')

        try:
            conn = httplib.HTTPSConnection('api.wmata.com')
            conn.request("GET", "/TrainPositions/TrainPositions?contentType={contentType}&%s" % params, "{body}", headers)
            response = conn.getresponse()
            data = response.read()
            print "{0}: Successfully pulled data".format(tz_now)
            conn.close()
        except Exception as e:
            data = "Uh oh, there was an error pulling the data"
            print "{0}: {1}".format(tz_now, data)
            print "[Errno {0}] {1}".format(e.errno, e.strerror)

        outfile_path = os.path.join(args.output_dir, tz_now)
        outfile = open(outfile_path, 'w')
        outfile.write(data)
        outfile.close()