// Netlify Serverless Function - Waitlist Proxy
// This keeps your Supabase keys secure on the server side

const { createClient } = require('@supabase/supabase-js');

exports.handler = async (event, context) => {
    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            body: JSON.stringify({ error: 'Method not allowed' })
        };
    }

    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }

    try {
        // Parse request body
        const { email, source } = JSON.parse(event.body);
        console.log('Received waitlist request:', { email, source });

        // Validate email
        if (!email || !email.includes('@')) {
            console.error('Invalid email:', email);
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: 'Invalid email address' })
            };
        }

        // Initialize Supabase client with environment variables
        const supabaseUrl = process.env.SUPABASE_URL;
        const supabaseKey = process.env.SUPABASE_ANON_KEY;

        console.log('Checking Supabase credentials...', {
            hasUrl: !!supabaseUrl,
            hasKey: !!supabaseKey,
            urlPrefix: supabaseUrl ? supabaseUrl.substring(0, 20) + '...' : 'missing'
        });

        if (!supabaseUrl || !supabaseKey) {
            console.error('Supabase credentials not configured');
            return {
                statusCode: 500,
                headers,
                body: JSON.stringify({ 
                    error: 'Server configuration error',
                    details: 'Environment variables not set'
                })
            };
        }

        const supabase = createClient(supabaseUrl, supabaseKey);

        console.log('Attempting to insert into Supabase...');

        // Insert into waitlist
        const { data, error } = await supabase
            .from('waitlist')
            .insert([{
                email: email,
                source: source || 'unknown',
                user_agent: event.headers['user-agent'] || null,
                referrer: event.headers.referer || null
            }]);

        if (error) {
            console.error('Supabase insert error:', error);
            
            // Check if it's a duplicate error
            if (error.code === '23505' || error.message.includes('duplicate')) {
                console.log('Duplicate email detected:', email);
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({ 
                        success: false, 
                        duplicate: true,
                        message: 'Email already on waitlist'
                    })
                };
            }

            return {
                statusCode: 500,
                headers,
                body: JSON.stringify({ 
                    error: 'Failed to add to waitlist',
                    details: error.message 
                })
            };
        }

        console.log('Successfully added to waitlist:', email, source);
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
                success: true,
                message: 'Successfully added to waitlist'
            })
        };

    } catch (error) {
        console.error('Function error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
                error: 'Internal server error',
                details: error.message 
            })
        };
    }
};

