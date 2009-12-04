package com.nosm.elearning.ariadne.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;

import org.apache.http.*;
import org.apache.http.client.*;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.*;
import org.apache.http.client.utils.*;
import org.apache.http.impl.client.*;

public abstract class HttpFetch {
	public static String getString4Url(String apiUrl, ArrayList qparams,
			boolean usePost) throws URISyntaxException, HttpResponseException,
			IOException, Exception {

		HttpClient httpclient = new DefaultHttpClient();
		StringBuffer sOut = new StringBuffer();

		String pOut = "";
		if (qparams != null && (!qparams.isEmpty())) {
			pOut = URLEncodedUtils.format(qparams, "UTF-8");
		}

		URI uri = URIUtils.createURI("http", Constants.GAME_HOST3, -1, apiUrl,
				pOut, null);

		HttpEntityEnclosingRequestBase httpRequest = null;
		HttpResponse response = null;

		if (usePost) {
			HttpPost hPost = new HttpPost(uri);
			hPost.setEntity(new UrlEncodedFormEntity(qparams));
			System.out.println(" HttpFetch, request method should be post: "
					+ hPost.getMethod() + ": " + uri.toString() + ", params:"
					+ hPost.getParams().getParameter("sessionid"));
			response = httpclient.execute(hPost);
		} else {
			HttpGet hGet = new HttpGet(uri);
			System.out.println(" HttpFetch, request method should be get: "
					+ hGet.getMethod() + ": " + uri.toString() + ", params:"
					+ hGet.getParams().getParameter("sessionid"));
			response = httpclient.execute(hGet);
		}
		if (response.getStatusLine().toString().toLowerCase().indexOf(
				"internal server error") > 0)
			throw new Exception("HttpFetch ERROR: URI " + uri
					+ " returned remote server error: "
					+ response.getStatusLine().toString());

		HttpEntity entity = response.getEntity();
		if (entity != null) {
			InputStream instream = entity.getContent();
			try {
				BufferedReader reader = new BufferedReader(
						new InputStreamReader(instream));
				String s;
				while ((s = reader.readLine()) != null)
					sOut.append(s);
			} catch (IOException ex) {
				throw ex;
			} catch (RuntimeException ex) {
				httpRequest.abort();
				throw ex;
			} finally {
				instream.close();
			}
			httpclient.getConnectionManager().shutdown();
		}
		return sOut.toString();
	}

}