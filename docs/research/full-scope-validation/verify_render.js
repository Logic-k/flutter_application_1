const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = __dirname;
const htmlPath = path.join(root, 'index.html');
const outDir = path.join(root, 'render-check');
const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const viewports = [
  { name: 'mobile-390', width: 390, height: 1400 },
  { name: 'tablet-768', width: 768, height: 1400 },
  { name: 'desktop-1280', width: 1280, height: 1400 },
];

function fileUrl(filePath) {
  return `file:///${filePath.replace(/\\/g, '/')}`;
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch({
    headless: true,
    executablePath: chromePath,
    args: ['--no-sandbox', '--disable-gpu'],
  });

  const results = [];
  for (const vp of viewports) {
    const page = await browser.newPage({ viewport: { width: vp.width, height: vp.height } });
    await page.goto(fileUrl(htmlPath), { waitUntil: 'load' });
    await page.emulateMedia({ media: 'screen' });
    const metrics = await page.evaluate(() => {
      const all = [...document.querySelectorAll('*')];
      const offenders = all
        .filter((el) => el.scrollWidth > el.clientWidth + 1)
        .map((el) => ({
          tag: el.tagName.toLowerCase(),
          className: String(el.className || ''),
          text: (el.textContent || '').trim().slice(0, 100),
          scrollWidth: el.scrollWidth,
          clientWidth: el.clientWidth,
        }))
        .slice(0, 20);
      return {
        title: document.title,
        bodyTextLength: document.body.innerText.length,
        documentScrollWidth: document.documentElement.scrollWidth,
        documentClientWidth: document.documentElement.clientWidth,
        bodyScrollWidth: document.body.scrollWidth,
        bodyClientWidth: document.body.clientWidth,
        offenders,
        headings: [...document.querySelectorAll('h1,h2,h3')].map((h) => h.textContent.trim()),
        internalLinks: [...document.querySelectorAll('a[href^="#"]')].map((a) => a.getAttribute('href')),
        brokenInternalLinks: [...document.querySelectorAll('a[href^="#"]')]
          .map((a) => a.getAttribute('href'))
          .filter((href) => !document.querySelector(href)),
        externalLinks: [...document.querySelectorAll('a[href^="https://"]')].length,
      };
    });

    const screenshotPath = path.join(outDir, `${vp.name}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    results.push({ viewport: vp, metrics, screenshot: screenshotPath });
    await page.close();
  }

  const printPage = await browser.newPage({ viewport: { width: 768, height: 1400 } });
  await printPage.goto(fileUrl(htmlPath), { waitUntil: 'load' });
  await printPage.emulateMedia({ media: 'print' });
  const printMetrics = await printPage.evaluate(() => ({
    bodyTextLength: document.body.innerText.length,
    detailsCount: document.querySelectorAll('details').length,
    hiddenContentCandidates: [...document.querySelectorAll('[hidden], [aria-hidden="true"]')].length,
    displayNoneCount: [...document.querySelectorAll('*')].filter((el) => getComputedStyle(el).display === 'none').length,
  }));
  const pdfPath = path.join(outDir, 'print.pdf');
  await printPage.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    margin: { top: '12mm', bottom: '12mm', left: '10mm', right: '10mm' },
  });
  await printPage.close();

  await browser.close();

  const summary = { checkedAt: new Date().toISOString(), htmlPath, chromePath, results, print: { metrics: printMetrics, pdf: pdfPath } };
  fs.writeFileSync(path.join(outDir, 'render-summary.json'), JSON.stringify(summary, null, 2), 'utf8');

  const failures = [];
  for (const r of results) {
    if (r.metrics.documentScrollWidth > r.metrics.documentClientWidth + 1) {
      failures.push(`${r.viewport.name}: document horizontal overflow ${r.metrics.documentScrollWidth}/${r.metrics.documentClientWidth}`);
    }
    if (r.metrics.offenders.length > 0) {
      failures.push(`${r.viewport.name}: element overflow ${JSON.stringify(r.metrics.offenders.slice(0, 3))}`);
    }
    if (r.metrics.internalLinks.length !== 8) {
      failures.push(`${r.viewport.name}: expected 8 internal nav links, found ${r.metrics.internalLinks.length}`);
    }
    if (r.metrics.brokenInternalLinks.length !== 0) {
      failures.push(`${r.viewport.name}: broken internal links ${r.metrics.brokenInternalLinks.join(', ')}`);
    }
    if (r.metrics.bodyTextLength < 8000) {
      failures.push(`${r.viewport.name}: unexpectedly short rendered text ${r.metrics.bodyTextLength}`);
    }
  }
  if (printMetrics.detailsCount !== 0) {
    failures.push(`print: details elements present ${printMetrics.detailsCount}`);
  }
  if (printMetrics.bodyTextLength < 8000) {
    failures.push(`print: unexpectedly short text ${printMetrics.bodyTextLength}`);
  }
  if (!fs.existsSync(pdfPath) || fs.statSync(pdfPath).size < 10000) {
    failures.push('print: PDF not created or too small');
  }

  if (failures.length) {
    console.error(JSON.stringify({ ok: false, failures }, null, 2));
    process.exit(1);
  }
  console.log(JSON.stringify({
    ok: true,
    screenshots: results.map((r) => path.relative(root, r.screenshot)),
    pdf: path.relative(root, pdfPath),
    textLengths: results.map((r) => ({ viewport: r.viewport.name, text: r.metrics.bodyTextLength })),
    printTextLength: printMetrics.bodyTextLength,
  }, null, 2));
})().catch((error) => {
  console.error(error.stack || error);
  process.exit(1);
});
