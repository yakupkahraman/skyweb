import { Hono } from 'hono';

const app = new Hono<{ Bindings: Env }>();

// Küçük harf a-z, Türkçe karakterler (çğıöşü), rakam ve tire.
// Baştaki/sondaki tireye izin verilmiyor.
const DOMAIN_PATTERN = /^[a-z0-9çğıöşü]([a-z0-9çğıöşü-]*[a-z0-9çğıöşü])?$/;

// Spam ve aşırı büyük girdilere karşı üst sınırlar.
const MAX_LABEL_LENGTH = 63; // domain ve tld için (DNS standardıyla aynı)
const MAX_REPO_LENGTH = 200;

function normalizeAndValidate(value: unknown): string | null {
	if (typeof value !== 'string') {
		return null;
	}
	// Regex'ten önce uzunluğu ele: devasa string'e regex çalıştırmayalım.
	if (value.length > MAX_LABEL_LENGTH) {
		return null;
	}
	const normalized = value.trim().toLowerCase();
	if (!DOMAIN_PATTERN.test(normalized)) {
		return null;
	}
	return normalized;
}

app.get('/resolve', async (c) => {
	const rawDomain = c.req.query('domain');
	const rawTld = c.req.query('tld');

	if (!rawDomain || !rawTld) {
		return c.json({ error: 'domain and tld are required' }, 400);
	}

	const domain = normalizeAndValidate(rawDomain);
	const tld = normalizeAndValidate(rawTld);

	if (!domain || !tld) {
		return c.json({ error: 'invalid domain or tld format' }, 400);
	}

	const result = await c.env.DB.prepare('SELECT repo FROM domains WHERE domain = ? AND tld = ?')
		.bind(domain, tld)
		.first();

	if (!result) {
		return c.json({ error: 'not found' }, 404);
	}

	return c.json(result);
});

app.post('/register', async (c) => {
	let body: any;
	try {
		body = await c.req.json();
	} catch {
		return c.json({ error: 'invalid JSON body' }, 400);
	}

	const { domain: rawDomain, tld: rawTld, repo } = body;

	if (!rawDomain || !rawTld || !repo) {
		return c.json({ error: 'domain, tld and repo are required' }, 400);
	}

	const domain = normalizeAndValidate(rawDomain);
	const tld = normalizeAndValidate(rawTld);

	if (!domain || !tld) {
		return c.json({ error: 'invalid domain or tld format' }, 400);
	}

	if (typeof repo !== 'string' || repo.length > MAX_REPO_LENGTH) {
		return c.json({ error: 'invalid repo' }, 400);
	}

	if (!/^[\w.-]+\/[\w.-]+(\/[\w.-]+)*$/.test(repo.trim())) {
		return c.json({ error: 'repo must be in the form "user/repo" or "user/repo/path/to/site"' }, 400);
	}

	try {
		await c.env.DB.prepare('INSERT INTO domains (domain, tld, repo) VALUES (?, ?, ?)')
			.bind(domain, tld, repo.trim())
			.run();

		return c.json({ success: true }, 201);
	} catch (err) {
		return c.json({ error: 'domain already taken' }, 409);
	}
});

export default app;