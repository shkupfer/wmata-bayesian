import argparse
import httplib
import urllib
import os
import json

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--wmata_api_key', '--key', default=os.getenv('WMATA_API_KEY'))
    parser.add_argument('output_dir', default='.')
    args = parser.parse_args()

    headers = {'api_key': args.wmata_api_key}
    params = urllib.urlencode({})
    try:
        conn = httplib.HTTPSConnection('api.wmata.com')
        conn.request("GET", "/TrainPositions/StandardRoutes?contentType={contentType}&%s" % params, "{body}",
                     headers)
        response = conn.getresponse()
        data = response.read()
        conn.close()
        outfile_path = os.path.join(args.output_dir, 'routes.json')
        with open(outfile_path, 'w') as outfile:
            outfile.write(data)
    except Exception as exp:
        print "Error: {0}".format(str(exp))

    all_lines = ['BL', 'GR', 'OR', 'RD', 'SV', 'YL']
    stations_data = {}
    for line in all_lines:
        params = urllib.urlencode({'LineCode': line})
        try:
            conn = httplib.HTTPSConnection('api.wmata.com')
            conn.request("GET", "/Rail.svc/json/jStations?%s" % params, "{body}", headers)
            response = conn.getresponse()
            stations_data[line] = json.loads(response.read().strip())
            conn.close()
        except Exception as exp:
            print "Error: {0}".format(str(exp))

    outfile_path = os.path.join(args.output_dir, 'stations.json')
    with open(outfile_path, 'w') as outfile:
        outfile.write(json.dumps(stations_data))