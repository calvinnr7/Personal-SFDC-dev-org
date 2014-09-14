/*
Purpose: bluewolf coding assignment - APEX Controller class for Visual force page. Performs callout to GeoNames APIs based on user input and send results to a JavaScript array in the CodingAssignment Visual force page.
Created:   11/15/2013
Programmer: Calvin Richard Noronha
Name: geoNamesController
*/

public with sharing class geoNamesController {
    //Declarations
    public List<EarthquakeDetails> eqDetailsList {get;set;} 
    public List<EarthquakeDetails> topTenQuakes {get;set;}  
    public string inputCity {get; set;}
    public string url;
    
    
    //Constructor
    public geoNamesController()
    {
        url = 'http://api.geonames.org';       

        //Go for the bonus!
        gettopTenEarthQuakes();
        
    }
    
    //Method which calls the Earthquake API to fetch the top 10 earthquakes for the last 1 year
    void gettopTenEarthQuakes()
    {       
        //Get today's date
        DateTime dt = Date.today();
        
        //1 year ago
        //dt = dt.addYears(-1);
        dt = dt.addYears(-2);
        //Update: 8/3/14: Calvin - The API is not returning earthquake data in the last 1 year for these bounding box coordinates. 
        
        
        System.debug('Date 1 year ago is ' + dt);
        
        //Format date to what the earthquake API expects i.e, yyyy-MM-dd
        //String fmtDate = dt.format('yyyy-MM-dd');
        //System.debug('Formatted date is ' + fmtDate);
        
        //Bounding box is the entire Earth, this means max latitude = 90(north), min latitude = -90(south), max longitude = 180(east), min longitude = -180(west)
        string topTenEarthquakeUrl = url + '/earthquakes?north=90&south=-90&east=180&west=-180&username=calvin_noronha'+'&maxRows=500&minMagnitude=6.8';
        System.debug('topTenEarthquakeUrl is ' + topTenEarthquakeUrl);        
        // Instantiate a new http object
        Http h = new Http();
        
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(topTenEarthquakeUrl);
        req.setMethod('GET');
        
        string response;
        // Send the request, and return a response
        //Don't do this when test is running        
        if(!Test.isrunningtest())
        {
            HttpResponse res = h.send(req);
            response = res.getBody();
        }
        else
        {
            //If test is running, give a mock response
            response = '<geonames><earthquake><src>us</src><eqid>c000dski</eqid><datetime>2013-11-01 18:02:05</datetime><lat>-29.1568</lat><lng>-71.2719</lng><magnitude>9.1</magnitude><depth>61.8</depth></earthquake><earthquake><src>us</src><eqid>c000dsbw</eqid><datetime>2012-11-14 4:21:43</datetime><lat>9.9914</lat><lng>122.4305</lng><magnitude>5.6</magnitude><depth>46.4</depth></earthquake></geonames>';
        }
        
        System.debug('Response from earthquake API for top ten quakes is ' + response);
        
        if (response != null)
        {
            //Parse response which is in XML format
            Dom.Document doc = new Dom.Document();
            doc.load(response);
                
            topTenQuakes = new List<EarthquakeDetails>();   
            //Retrieve the root element for this document.
            Dom.XMLNode geonames = doc.getRootElement();    
            for(integer i=0; i < geonames.getChildElements().size(); i++)         
            { 
                //Loop through child nodes and collect data to display in VF page
                Dom.XMLNode earthQuake = geonames.getChildElements()[i];
                String dateOccured = earthQuake.getChildElement('datetime', null).getText();
                Datetime dateOfOccurence = Datetime.valueOf(dateOccured);
                
                //Check if quake occured in the last 12 months, only add 10 entries
                if (dateOfOccurence > dt && dateOfOccurence<=Date.today() && topTenQuakes.size() < 10)
                {
                
                    String eqid = earthQuake.getChildElement('eqid', null).getText();
                    
                    String latStr = earthQuake.getChildElement('lat', null).getText();
                    Decimal lat = Decimal.valueOf(latStr);
                    
                    String lngStr = earthQuake.getChildElement('lng', null).getText();
                    Decimal lng = Decimal.valueOf(lngStr);
                    
                    String magStr = earthQuake.getChildElement('magnitude', null).getText();
                    Decimal mag = Decimal.valueOf(magStr);
                    
                    String depthStr = earthQuake.getChildElement('depth', null).getText();
                    Decimal depth = Decimal.valueOf(depthStr);
                    
                    System.debug('*** Data from top 10 earthquakes ***');
                    System.debug('eqid: ' + eqid);
                    System.debug('dateOccured: ' + dateOccured);                
                    System.debug('Lat: ' + lat);
                    System.debug('Lng: ' + lng);
                    System.debug('magnitude: ' + mag);
                    System.debug('depth: ' + depth);
                    
                    //New Quake details object
                    EarthquakeDetails eq = new EarthquakeDetails(eqid,lat, lng, dateOfOccurence,  mag, depth);
                    System.debug('eq is ' + eq);
                    topTenQuakes.add(eq);
                }
                
            }
            System.debug('topTenQuakes size is ' + topTenQuakes);
            
        }
        
        
        
    }
    
    //Method to get the user input and perform a callout to the GeoNames search API
    public void runSearch()
    {
        //Params for Earthquake API
        decimal north = 0;
        decimal south = 0;
        decimal east = 0;
        decimal west = 0;
        
        try
        {       
            string geonamesUrl;
            string searchAPIResponse;
            
            if(inputCity.isNumeric())
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The input cannot contain only numeric characters'));
            }
            else if (String.isNotBlank(inputCity))
            {
                searchAPIResponse = getCityCoordinates(inputCity);
            
            
                if (searchAPIResponse != null)
                {
                
                    //Parse response which is in XML format
                    Dom.Document doc = new Dom.Document();
                    doc.load(searchAPIResponse);
                    
                    
                    //Retrieve the root element for this document.
                    Dom.XMLNode root = doc.getRootElement();    
                    
                    //Get the first result only
                    //Future enhancement will be to display perhaps the first 10 results so that the user can select the desired location.  
                    String name;
                    String lat;
                    String lng;
                                        
                    if (root.getChildElement('totalResultsCount', null).getText() == '0')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'No data found for the given location. Please try with a different keyword.'));
                    }
                    else
                    {
                        Dom.XMLNode geoname = root.getChildElements()[1];   
                        
                        if (geoname != null)
                        {           
                            name = geoname.getChildElement('name', null).getText();
                            lat = geoname.getChildElement('lat', null).getText();
                            lng = geoname.getChildElement('lng', null).getText();
                            System.debug('Name: ' + name);
                            System.debug('Lat: ' + lat);
                            System.debug('Lng: ' + lng);
                        }
                    }
                    
                    
                    BoundingBox bbox;
                    if (lat !=null && lng != null)
                    {
                        Decimal latDecimal = Decimal.valueOf(lat);
                        Decimal lngDecimal = Decimal.valueOf(lng);
                        bbox = new BoundingBox();
                        bbox.calculateBoundingBox(latDecimal, lngDecimal);
                    }
                    
                    String earthQuakeResponse;
                    if (bbox != null)
                    {
                        //Make call to the GeoNames Earthquake API 
                        earthQuakeResponse = getEarthQuakeLocations(bbox);
                        if (earthQuakeResponse != null)
                        {
                            //Parse response which is in JSON format                    
                            eqDetailsList = new List <EarthquakeDetails>();
                            JSONParser parser = JSON.createParser(earthQuakeResponse);
                            while (parser.nextToken() != null) 
                            {
                                // Start at the array of earthquakes.
                                if (parser.getCurrentToken() == JSONToken.START_ARRAY) 
                                {
                                    
                                    while (parser.nextToken() != null) 
                                    {
                                        // Advance to the start object marker to
                                        // find next invoice statement object.
                                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                                        {                                   
                                            // Read entire earthquakes object, including its array of line items.
                                            EarthquakeDetails eq = (EarthquakeDetails)parser.readValueAs(EarthquakeDetails.class);
                                            if (eq !=null)
                                            {
                                                eqDetailsList.add(eq);
                                            }                               
                                            
                                            // Skip the child start array and start object markers.
                                            parser.skipChildren();
                                        }
                                    }
                                 }
                             }
                         }
                     }
                
                    System.debug('eqDetailsList size is ' + eqDetailsList.size());
                
                }
            
            }
            else
            {
                //input is null
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter a value in the input text box before clicking the Search button')); 
            }
        
        

        
        
        
        }
        catch(Exception e)
        {
            System.debug('Exception occured' + e);
        }
        
        
        //String name = address.getChildElement('name', null).getText();
        //String state = address.getChildElement('state', null).getText();
        // print out specific elements
        //System.debug('Name: ' + name);
        //System.debug('State: ' + state);
        
        
        
        
    }
    
    //Method to make a call to the Geonames search API to return the latitude and longitude for the location entered by the user
    public string getCityCoordinates(string inputCity)
    {
        String response;
        string geonamesUrl;
        
        //Construct URL
        if (inputCity != null)
        {
        	inputCity = inputCity.trim().replace(' ','_');        	
            geonamesUrl = url + '/search?q='+inputCity +'&maxRows=1&username=calvin_noronha';
        }
        
        
        System.debug('geonamesUrl is ' + geonamesUrl);
        // Instantiate a new http object
        Http h = new Http();
        
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint(geonamesUrl);
        req.setMethod('GET');
        
        // Send the request, and return a response
        //Don't do this when test is running        
        if(!Test.isrunningtest())
        {
            HttpResponse res = h.send(req);
            response = res.getBody();
        }
        else
        {
            //If test is running, give a mock response
            response = '<geonames style="MEDIUM"><totalResultsCount>5324</totalResultsCount><geoname><toponymName>London</toponymName><name>London</name><lat>51.50853</lat><lng>-0.12574</lng><geonameId>2643743</geonameId><countryCode>GB</countryCode><countryName>United Kingdom</countryName><fcl>P</fcl><fcode>PPLC</fcode></geoname><geoname><toponymName>East London</toponymName><name>East London</name><lat>-33.01529</lat><lng>27.91162</lng><geonameId>1006984</geonameId><countryCode>ZA</countryCode><countryName>South Africa</countryName><fcl>P</fcl><fcode>PPLA2</fcode></geoname></geonames>';
        }
        System.debug('Response from search API is ' + response);
        return response; 
    }
    
    //Method to make a call to the Geonames Earthquake API to return the quake locations
    Public string getEarthQuakeLocations(BoundingBox bbox)
    {
        String response;
        if (bbox != null)
        {
            decimal north = bbox.north;
            decimal south = bbox.south;
            decimal east = bbox.east;
            decimal west = bbox.west;
            
            //ONLY first 10 results are returned by default
            string earthQuakeUrl = url + '/earthquakesJSON?'+ 'north='+north+'&south='+south+'&east='+east+'&west='+west+'&username=calvin_noronha';
            
            System.debug('earthQuakeUrl is ' + earthQuakeUrl);
            
            // Instantiate a new http object
            Http h = new Http();
            
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(earthQuakeUrl);
            req.setMethod('GET');
            
            // Send the request, and return a response
            //Don't do this when test is running        
            if(!Test.isrunningtest())
            {
                HttpResponse res = h.send(req);
                response = res.getBody();
            }
            else
            {
                //If test is running, give a mock response
                response = '{"earthquakes":[{"eqid":"2007bsal","magnitude":4.7,"lng":1.03,"src":"us","datetime":"2007-04-28 05:18:11","depth":10,"lat":51.024},{"eqid":"c0005r6w","magnitude":4.2,"lng":5.9598,"src":"us","datetime":"2011-09-08 17:02:47","depth":14.3,"lat":51.779}]}';
            }
            
            System.debug('Response from EarthQuake API is ' + response);
            
            
            
        }
        return response;
    }
    
    // Wrapper classes used for storing values after deserializing JSON response from the Earthquake API.
    public class EarthquakeDetails      
    {   
        public string eqid{get;set;}
        public decimal lat{get;set;}
        public decimal lng{get;set;}
        public datetime dateOfOccurence{get;set;}
        public decimal magnitude{get;set;}
        public decimal depth{get;set;}
        
        public EarthquakeDetails(string eqid,decimal lat, decimal lng, datetime dateOfOccurence, decimal magnitude,decimal depth)
        {
            this.eqid = eqid;
            this.lat = lat;
            this.lng = lng;
            this.dateOfOccurence = dateOfOccurence;
            this.magnitude = magnitude;
            this.depth = depth;
        }
    }
    
    //Class to store the bounding box parameters
    public class BoundingBox
    {
        public decimal north;
        public decimal south;
        public decimal east;
        public decimal west;
        public decimal adjustment;
        
        //Contructor - Initialize to zero
        public BoundingBox()
        {
            this.north = 0;
            this.south = 0;
            this.east = 0;
            this.west = 0;
            adjustment = 10;
        }
        
        //Method to calculate bounding box for the given latitude and longitude
        public void calculateBoundingBox(decimal lat, decimal lng)
        {
            //The last time I took a geography course was in 10th grade and that seems so long long ago in a galaxy far far away
            //The search API returns the lat and lng coordinates
            //Based on online reference, we will add/subtract 10 degree to/from the obtain coordinates to get a bounding box
            //Used this page to determine 10 would be an reasonable value for bounding box - http://www.openstreetmap.org/export
            //Futher enhancement will be calculate this more precisely
            
            if (lat != null && lng != null)
            {

                this.north = lat + adjustment;
                this.south = lat - adjustment;
                this.east = lng + adjustment;
                this.west = lng - adjustment;
                
                System.debug('north: ' + this.north);
                System.debug('south: ' + this.south);
                System.debug('east: ' + this.east);
                System.debug('west: ' + this.west);
            }
                
        }
        
    }
    
    
    //Test method   
    static testMethod void main_test() 
    {
        Test.startTest();
        //Test constructor
        geoNamesController gc = new geoNamesController();
        System.assertNotEquals(gc, null);
        //Test search functionality
        gc.inputCity = 'London';
        gc.runSearch();
        
        gc.inputCity = '';
        gc.runSearch();
        
        gc.inputCity = '123';
        gc.runSearch();
        
        //Check if bounding box is calculated properly
        BoundingBox bbox = new BoundingBox();
        bbox.calculateBoundingBox(20, 30);
        System.assertEquals(bbox.north, 30 );
        System.assertEquals(bbox.south, 10 );
        System.assertEquals(bbox.east, 40 );
        System.assertEquals(bbox.west, 20 );
        
        //Check if wrapper class initializes properly
        EarthquakeDetails eq = new EarthquakeDetails('244567',50.67, -9.8, System.Now(), 7.1,3.1);
        System.assertNotEquals(eq, null);
        Test.stopTest();        
        
    }   
    
    
    
        
        
        
        
}