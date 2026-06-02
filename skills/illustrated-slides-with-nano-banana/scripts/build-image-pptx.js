/**
 * Build a PowerPoint presentation from slide images.
 * Each image becomes a full-page slide (16:9).
 * 
 * Usage:
 *   node build-image-pptx.js <slides-dir> <output.pptx> [title]
 * 
 * Example:
 *   node build-image-pptx.js ./slides ./output.pptx "My Presentation"
 * 
 * Slide images should be named with numeric prefixes for ordering:
 *   01-title.png, 02-intro.png, 03-content.png, etc.
 */

const pptxgen = require('pptxgenjs');
const fs = require('fs');
const path = require('path');

async function buildImagePresentation(slidesDir, outputPath, title = 'AI-Generated Presentation') {
    const pptx = new pptxgen();
    
    // Set presentation properties
    pptx.layout = 'LAYOUT_16x9';
    pptx.title = title;
    pptx.author = 'AI Generated with Nano Banana';
    
    // Get slide images in order (01-*.png, 02-*.png, etc.)
    const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
    const slides = fs.readdirSync(slidesDir)
        .filter(f => {
            const ext = path.extname(f).toLowerCase();
            return imageExtensions.includes(ext) && f.match(/^\d{2}-/);
        })
        .sort();
    
    if (slides.length === 0) {
        console.error('No slide images found. Images should be named like: 01-title.png, 02-intro.png, etc.');
        process.exit(1);
    }
    
    console.log(`Found ${slides.length} slide images...`);
    
    for (const file of slides) {
        const imagePath = path.join(slidesDir, file);
        console.log(`  Adding: ${file}`);
        
        const slide = pptx.addSlide();
        slide.addImage({
            path: imagePath,
            x: 0,
            y: 0,
            w: '100%',
            h: '100%',
            sizing: { type: 'cover', w: '100%', h: '100%' }
        });
    }
    
    await pptx.writeFile({ fileName: outputPath });
    console.log(`\n✅ Presentation saved: ${outputPath}`);
    console.log(`   ${slides.length} slides total`);
}

// CLI interface
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('Usage: node build-image-pptx.js <slides-dir> <output.pptx> [title]');
        console.log('');
        console.log('Example:');
        console.log('  node build-image-pptx.js ./slides ./presentation.pptx "My Deck"');
        process.exit(1);
    }
    
    const [slidesDir, outputPath, title] = args;
    
    if (!fs.existsSync(slidesDir)) {
        console.error(`Slides directory not found: ${slidesDir}`);
        process.exit(1);
    }
    
    buildImagePresentation(slidesDir, outputPath, title).catch(err => {
        console.error('Error:', err.message);
        process.exit(1);
    });
}

module.exports = buildImagePresentation;
