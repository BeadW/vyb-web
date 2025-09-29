# VYB Canvas - Production Deployment Guide

## Build Commands

### Development
```bash
npm run dev
```
- Starts development server on http://localhost:3000
- Hot module replacement enabled
- Source maps included
- Debug logging enabled

### Production Build
```bash
npm run build
```
- Optimized production bundle
- Minified assets
- Source maps for debugging
- Assets hashed for caching
- Bundle analysis available

### Preview Production Build
```bash
npm run preview
```
- Serves production build locally
- Tests production optimizations
- Verifies build integrity

## Performance Optimizations

### Bundle Splitting
- React/React-DOM in separate chunk
- Fabric.js in vendor chunk
- App code in main chunk
- Dynamic imports for large components

### Asset Optimization
- CSS minification and purging
- Image optimization (WebP/AVIF support)
- Font subsetting and preloading
- Resource hints (preload, prefetch)

### Runtime Optimizations
- Service Worker for caching
- Code splitting at route level
- Lazy loading for heavy components
- Virtual scrolling for large lists

## Deployment Targets

### Static Hosting (Recommended)
- **Vercel**: Zero-config deployment with Git integration
- **Netlify**: Automatic builds and CDN distribution
- **GitHub Pages**: Free hosting for public repositories
- **AWS S3 + CloudFront**: Enterprise-grade with custom domain

### Container Deployment
```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### CDN Configuration
- Cache static assets for 1 year
- Cache HTML for 1 hour
- Enable gzip/brotli compression
- Set proper CORS headers

## Environment Configuration

### Environment Variables
```bash
# API Configuration
VITE_API_BASE_URL=https://api.vyb.app
VITE_GEMINI_API_KEY=your_gemini_api_key

# Feature Flags
VITE_ENABLE_AI_FEATURES=true
VITE_ENABLE_ANALYTICS=true
VITE_DEBUG_MODE=false

# Build Configuration
VITE_BUILD_TARGET=modern
VITE_BUNDLE_ANALYZER=false
```

### Build Variants
- **development**: Full debugging, hot reload
- **staging**: Production optimizations, debug logs
- **production**: Maximum optimizations, analytics

## Monitoring & Analytics

### Performance Monitoring
- Core Web Vitals tracking
- Bundle size monitoring
- Runtime error reporting
- User interaction analytics

### Error Handling
- Global error boundary
- Unhandled promise rejection capture
- Network error recovery
- Graceful degradation

## Security Considerations

### Content Security Policy
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline';
               style-src 'self' 'unsafe-inline';
               img-src 'self' data: https:;
               connect-src 'self' https://api.vyb.app;">
```

### Asset Integrity
- Subresource integrity (SRI) hashes
- HTTPS-only in production
- Secure cookie configuration
- XSS protection headers

## Browser Support

### Target Browsers
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile Safari iOS 14+
- Chrome Mobile 90+

### Polyfills Included
- ES6+ features via Vite/esbuild
- CSS custom properties
- Intersection Observer
- ResizeObserver

## File Structure

```
dist/
├── index.html              # Entry point with optimized loading
├── assets/
│   ├── index-[hash].js     # Main application bundle
│   ├── vendor-[hash].js    # Third-party dependencies
│   ├── index-[hash].css    # Compiled styles
│   └── images/             # Optimized images
└── manifest.json           # PWA manifest
```

## Quality Assurance

### Pre-deployment Checklist
- [ ] Build completes without errors
- [ ] All routes load correctly
- [ ] Canvas functionality works
- [ ] Device simulation responsive
- [ ] AI features operational
- [ ] Performance metrics acceptable
- [ ] Accessibility compliance
- [ ] Cross-browser testing complete

### Performance Budgets
- Initial bundle: < 500KB gzipped
- First Contentful Paint: < 2s
- Largest Contentful Paint: < 4s
- Cumulative Layout Shift: < 0.1
- Time to Interactive: < 5s