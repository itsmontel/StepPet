/* ======================================
   VirtuPet Website JavaScript
   Animations, Interactivity, and Magic
   ====================================== */

// Waitlist API endpoint (Netlify serverless function)
// Keys are stored securely on the server side
const WAITLIST_API_URL = '/.netlify/functions/waitlist';

document.addEventListener('DOMContentLoaded', () => {
    // No client-side Supabase initialization needed
    // All API calls go through the secure Netlify function
    
    // Initialize all components
    initParticles();
    initNavbar();
    initMobileMenu();
    initHeroPetCarousel();
    initPetShowcase();
    initScrollAnimations();
    initCounterAnimations();
    initFAQ();
    initModals();
    initWaitlist();
    initWaitlistPopup();
});

/* ======================================
   FLOATING PARTICLES
   ====================================== */
function initParticles() {
    const particlesContainer = document.getElementById('particles');
    const emojis = ['🐾', '⭐', '❤️', '✨', '🌟', '💫', '🎮', '👟'];
    
    // Create initial particles
    for (let i = 0; i < 15; i++) {
        createParticle(particlesContainer, emojis, i * 2);
    }
    
    // Continue creating particles
    setInterval(() => {
        if (document.querySelectorAll('.particle').length < 20) {
            createParticle(particlesContainer, emojis, 0);
        }
    }, 3000);
}

function createParticle(container, emojis, delay) {
    const particle = document.createElement('div');
    particle.className = 'particle';
    particle.textContent = emojis[Math.floor(Math.random() * emojis.length)];
    particle.style.left = `${Math.random() * 100}%`;
    particle.style.animationDelay = `${delay}s`;
    particle.style.animationDuration = `${15 + Math.random() * 10}s`;
    container.appendChild(particle);
    
    // Remove particle after animation
    setTimeout(() => {
        particle.remove();
    }, (15 + delay) * 1000);
}

/* ======================================
   NAVBAR SCROLL EFFECT
   ====================================== */
function initNavbar() {
    const navbar = document.querySelector('.navbar');
    let lastScrollY = window.scrollY;
    
    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        
        // Add scrolled class
        if (currentScrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
        
        lastScrollY = currentScrollY;
    });
    
    // Smooth scroll for anchor links with offset for fixed navbar
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            
            // Skip if it's just "#" or has an ID that should be handled by modal
            if (!targetId || targetId === '#' || this.id === 'openPrivacy' || this.id === 'openTerms') {
                return;
            }
            
            e.preventDefault();
            const target = document.querySelector(targetId);
            
            if (target) {
                const navbarHeight = navbar.offsetHeight;
                const targetPosition = target.getBoundingClientRect().top + window.scrollY - navbarHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
                
                // Close mobile menu if open
                closeMobileMenu();
            }
        });
    });
}

/* ======================================
   MOBILE MENU
   ====================================== */
function initMobileMenu() {
    const menuToggle = document.getElementById('mobileMenuToggle');
    const navLinks = document.getElementById('navLinks');
    const overlay = document.getElementById('mobileMenuOverlay');
    
    if (!menuToggle || !navLinks || !overlay) return;
    
    // Toggle menu on button click
    menuToggle.addEventListener('click', () => {
        const isOpen = navLinks.classList.contains('active');
        
        if (isOpen) {
            closeMobileMenu();
        } else {
            openMobileMenu();
        }
    });
    
    // Close menu when clicking overlay
    overlay.addEventListener('click', closeMobileMenu);
    
    // Close menu on escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeMobileMenu();
        }
    });
    
    // Close menu on window resize (if desktop)
    window.addEventListener('resize', () => {
        if (window.innerWidth > 768) {
            closeMobileMenu();
        }
    });
}

function openMobileMenu() {
    const menuToggle = document.getElementById('mobileMenuToggle');
    const navLinks = document.getElementById('navLinks');
    const overlay = document.getElementById('mobileMenuOverlay');
    
    menuToggle.classList.add('active');
    menuToggle.setAttribute('aria-expanded', 'true');
    navLinks.classList.add('active');
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeMobileMenu() {
    const menuToggle = document.getElementById('mobileMenuToggle');
    const navLinks = document.getElementById('navLinks');
    const overlay = document.getElementById('mobileMenuOverlay');
    
    if (!menuToggle || !navLinks || !overlay) return;
    
    menuToggle.classList.remove('active');
    menuToggle.setAttribute('aria-expanded', 'false');
    navLinks.classList.remove('active');
    overlay.classList.remove('active');
    document.body.style.overflow = '';
}

/* ======================================
   HERO VIDEO SHOWCASE
   ====================================== */
function initHeroPetCarousel() {
    const videoShowcase = document.getElementById('videoShowcase');
    if (!videoShowcase) return;
    
    const videos = videoShowcase.querySelectorAll('.showcase-video');
    const indicators = videoShowcase.querySelectorAll('.video-indicator');
    
    if (videos.length === 0) return;
    
    let currentVideo = 0;
    let isTransitioning = false;
    
    // Function to transition to a specific video
    function transitionToVideo(index) {
        if (isTransitioning || index === currentVideo) return;
        isTransitioning = true;
        
        const prevVideo = videos[currentVideo];
        const nextVideo = videos[index];
        
        // Update indicators
        indicators[currentVideo].classList.remove('active');
        indicators[index].classList.add('active');
        
        // Fade out current video
        prevVideo.classList.add('fade-out');
        prevVideo.classList.remove('active');
        
        // Prepare and show next video
        nextVideo.currentTime = 0;
        nextVideo.classList.add('active');
        nextVideo.play().catch(() => {}); // Ignore autoplay errors
        
        // Clean up after transition
        setTimeout(() => {
            prevVideo.classList.remove('fade-out');
            prevVideo.pause();
            prevVideo.currentTime = 0;
            currentVideo = index;
            isTransitioning = false;
        }, 800);
    }
    
    // Function to go to next video
    function nextVideo() {
        const nextIndex = (currentVideo + 1) % videos.length;
        transitionToVideo(nextIndex);
    }
    
    // Initialize first video
    videos[0].play().catch(() => {});
    
    // Listen for video end to transition to next
    videos.forEach((video, index) => {
        video.addEventListener('ended', () => {
            if (index === currentVideo) {
                nextVideo();
            }
        });
        
        // Fallback: if video doesn't end properly, transition after 8 seconds
        video.addEventListener('play', () => {
            // Clear any existing timeout
            if (video.transitionTimeout) {
                clearTimeout(video.transitionTimeout);
            }
            // Set a max duration timeout (in case video duration is unknown)
            video.transitionTimeout = setTimeout(() => {
                if (index === currentVideo && !isTransitioning) {
                    nextVideo();
                }
            }, 10000); // 10 second max per video
        });
    });
    
    // Click on indicators to jump to that video
    indicators.forEach((indicator, index) => {
        indicator.addEventListener('click', () => {
            transitionToVideo(index);
        });
    });
    
    // Auto-advance fallback interval (in case ended event doesn't fire)
    setInterval(() => {
        // Check if current video is paused or ended
        const current = videos[currentVideo];
        if (current.paused || current.ended) {
            nextVideo();
        }
    }, 12000);
}

/* ======================================
   PET SHOWCASE TABS
   ====================================== */
function initPetShowcase() {
    const petBtns = document.querySelectorAll('.pet-btn');
    const petPanels = document.querySelectorAll('.pet-panel');
    
    petBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const petType = btn.dataset.pet;
            
            // Update buttons
            petBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            // Update panels
            petPanels.forEach(panel => {
                panel.classList.remove('active');
                if (panel.dataset.pet === petType) {
                    panel.classList.add('active');
                }
            });
            
            // Add bounce animation to clicked button
            btn.style.transform = 'scale(1.1)';
            setTimeout(() => {
                btn.style.transform = '';
            }, 200);
        });
    });
}

/* ======================================
   SCROLL ANIMATIONS (Intersection Observer)
   ====================================== */
function initScrollAnimations() {
    // Feature rows
    observeElements('.feature-row', (entry) => {
        const delay = entry.target.dataset.delay || 0;
        setTimeout(() => {
            entry.target.classList.add('visible');
        }, parseInt(delay));
    });
    
    // Game cards
    observeElements('.game-card', (entry) => {
        const delay = entry.target.dataset.delay || 0;
        setTimeout(() => {
            entry.target.classList.add('visible');
        }, parseInt(delay));
    });
    
    // Step cards
    observeElements('.step-card', (entry) => {
        entry.target.classList.add('visible');
    });
    
    // Review cards
    observeElements('.review-card', (entry) => {
        const delay = entry.target.dataset.delay || 0;
        setTimeout(() => {
            entry.target.classList.add('visible');
        }, parseInt(delay));
    });
}

function observeElements(selector, callback, threshold = 0.2) {
    const elements = document.querySelectorAll(selector);
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                callback(entry);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold });
    
    elements.forEach(el => observer.observe(el));
}

/* ======================================
   COUNTER ANIMATIONS
   ====================================== */
function initCounterAnimations() {
    const counters = document.querySelectorAll('.stat-number');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    counters.forEach(counter => observer.observe(counter));
}

function animateCounter(element) {
    const target = parseFloat(element.dataset.count);
    const isDecimal = target % 1 !== 0;
    const duration = 2000;
    const steps = 60;
    const stepTime = duration / steps;
    let current = 0;
    
    const timer = setInterval(() => {
        current += target / steps;
        
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }
        
        if (isDecimal) {
            element.textContent = current.toFixed(1);
        } else if (target >= 1000) {
            element.textContent = formatNumber(Math.floor(current));
        } else {
            element.textContent = Math.floor(current);
        }
    }, stepTime);
}

function formatNumber(num) {
    if (num >= 1000) {
        return (num / 1000).toFixed(0) + 'K+';
    }
    return num.toString();
}

/* ======================================
   MOOD CARD HOVER EFFECTS
   ====================================== */
document.addEventListener('DOMContentLoaded', () => {
    const moodCards = document.querySelectorAll('.mood-card');
    
    moodCards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            const img = card.querySelector('img');
            if (img) {
                img.style.transform = 'scale(1.1)';
            }
        });
        
        card.addEventListener('mouseleave', () => {
            const img = card.querySelector('img');
            if (img) {
                img.style.transform = 'scale(1)';
            }
        });
    });
});

/* ======================================
   PARALLAX EFFECT FOR FLOATING ELEMENTS
   ====================================== */
document.addEventListener('mousemove', (e) => {
    const floatingElements = document.querySelectorAll('.float-element');
    const mouseX = e.clientX / window.innerWidth - 0.5;
    const mouseY = e.clientY / window.innerHeight - 0.5;
    
    floatingElements.forEach((el, index) => {
        const speed = (index + 1) * 20;
        const x = mouseX * speed;
        const y = mouseY * speed;
        el.style.transform = `translate(${x}px, ${y}px)`;
    });
});

/* ======================================
   PHONE MOCKUP TILT EFFECT
   ====================================== */
document.addEventListener('DOMContentLoaded', () => {
    const phoneMockup = document.querySelector('.phone-mockup');
    
    if (phoneMockup) {
        document.addEventListener('mousemove', (e) => {
            const rect = phoneMockup.getBoundingClientRect();
            const centerX = rect.left + rect.width / 2;
            const centerY = rect.top + rect.height / 2;
            
            const mouseX = e.clientX - centerX;
            const mouseY = e.clientY - centerY;
            
            const rotateX = (mouseY / window.innerHeight) * 10;
            const rotateY = (mouseX / window.innerWidth) * -10;
            
            phoneMockup.style.transform = `
                translateY(-${Math.sin(Date.now() / 1000) * 10}px)
                rotateX(${rotateX}deg)
                rotateY(${rotateY}deg)
            `;
        });
    }
});

/* ======================================
   BUTTON RIPPLE EFFECT
   ====================================== */
document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('click', function(e) {
        const rect = this.getBoundingClientRect();
        const ripple = document.createElement('span');
        
        ripple.style.cssText = `
            position: absolute;
            background: rgba(255, 255, 255, 0.4);
            border-radius: 50%;
            pointer-events: none;
            width: 100px;
            height: 100px;
            transform: translate(-50%, -50%) scale(0);
            animation: ripple 0.6s ease-out;
        `;
        
        ripple.style.left = `${e.clientX - rect.left}px`;
        ripple.style.top = `${e.clientY - rect.top}px`;
        
        this.appendChild(ripple);
        
        setTimeout(() => ripple.remove(), 600);
    });
});

// Add ripple animation to stylesheet
const style = document.createElement('style');
style.textContent = `
    @keyframes ripple {
        to {
            transform: translate(-50%, -50%) scale(4);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

/* ======================================
   LAZY LOADING FOR GIFS
   ====================================== */
document.addEventListener('DOMContentLoaded', () => {
    const gifImages = document.querySelectorAll('img[src$=".gif"]');
    
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                // Trigger reload to restart GIF animation
                const src = img.src;
                img.src = '';
                img.src = src;
                imageObserver.unobserve(img);
            }
        });
    }, { rootMargin: '100px' });
    
    gifImages.forEach(img => imageObserver.observe(img));
});

/* ======================================
   SCROLL PROGRESS INDICATOR
   ====================================== */
document.addEventListener('DOMContentLoaded', () => {
    const progressBar = document.createElement('div');
    progressBar.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        height: 3px;
        background: linear-gradient(90deg, #FF6B4A, #FFD93D);
        z-index: 10000;
        transition: width 0.1s ease;
        width: 0%;
    `;
    document.body.appendChild(progressBar);
    
    window.addEventListener('scroll', () => {
        const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
        const progress = (window.scrollY / scrollHeight) * 100;
        progressBar.style.width = `${progress}%`;
    });
});

/* ======================================
   EASTER EGG: KONAMI CODE
   ====================================== */
const konamiCode = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];
let konamiIndex = 0;

document.addEventListener('keydown', (e) => {
    if (e.key === konamiCode[konamiIndex]) {
        konamiIndex++;
        if (konamiIndex === konamiCode.length) {
            triggerEasterEgg();
            konamiIndex = 0;
        }
    } else {
        konamiIndex = 0;
    }
});

function triggerEasterEgg() {
    const emojis = ['🐕', '🐱', '🐰', '🐹', '🐴', '❤️', '⭐', '✨'];
    
    for (let i = 0; i < 50; i++) {
        setTimeout(() => {
            const emoji = document.createElement('div');
            emoji.textContent = emojis[Math.floor(Math.random() * emojis.length)];
            emoji.style.cssText = `
                position: fixed;
                font-size: ${30 + Math.random() * 40}px;
                left: ${Math.random() * 100}vw;
                top: -50px;
                z-index: 10001;
                pointer-events: none;
                animation: fall ${2 + Math.random() * 3}s linear forwards;
            `;
            document.body.appendChild(emoji);
            
            setTimeout(() => emoji.remove(), 5000);
        }, i * 50);
    }
    
    // Add fall animation
    const fallStyle = document.createElement('style');
    fallStyle.textContent = `
        @keyframes fall {
            to {
                transform: translateY(110vh) rotate(720deg);
            }
        }
    `;
    document.head.appendChild(fallStyle);
}

/* ======================================
   PERFORMANCE: THROTTLE SCROLL EVENTS
   ====================================== */
function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Apply throttle to scroll-heavy operations
window.addEventListener('scroll', throttle(() => {
    // Add any additional scroll handlers here
}, 16)); // ~60fps

/* ======================================
   FAQ ACCORDION
   ====================================== */
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');
    
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        
        question.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            // Close all other items
            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                    otherItem.querySelector('.faq-question').setAttribute('aria-expanded', 'false');
                }
            });
            
            // Toggle current item
            item.classList.toggle('active');
            question.setAttribute('aria-expanded', !isActive);
        });
    });
}

/* ======================================
   MODAL FUNCTIONALITY
   ====================================== */
function initModals() {
    const privacyModal = document.getElementById('privacyModal');
    const termsModal = document.getElementById('termsModal');
    const openPrivacy = document.getElementById('openPrivacy');
    const openTerms = document.getElementById('openTerms');
    
    // Open Privacy Modal
    if (openPrivacy && privacyModal) {
        openPrivacy.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            openModal(privacyModal);
        });
    }
    
    // Open Terms Modal
    if (openTerms && termsModal) {
        openTerms.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            openModal(termsModal);
        });
    }
    
    // Close modal on overlay click
    document.querySelectorAll('.modal-overlay').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal(modal);
            }
        });
    });
    
    // Close modal on close button click
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => {
            const modal = btn.closest('.modal-overlay');
            closeModal(modal);
        });
    });
    
    // Close modal on escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-overlay.active').forEach(modal => {
                closeModal(modal);
            });
        }
    });
}

function openModal(modal) {
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal(modal) {
    modal.classList.remove('active');
    document.body.style.overflow = '';
}

console.log('🐾 VirtuPet Website Loaded! Welcome to the cutest fitness app ever!');
console.log('💡 Psst... try the Konami Code for a surprise! ↑↑↓↓←→←→BA');

/* ======================================
   WAITLIST FUNCTIONALITY
   ====================================== */
function initWaitlist() {
    // Get all waitlist forms
    const waitlistBarForm = document.getElementById('waitlistBarForm');
    const waitlistMainForm = document.getElementById('waitlistMainForm');
    const footerWaitlistForm = document.getElementById('footerWaitlistForm');
    const waitlistPopupForm = document.getElementById('waitlistPopupForm');
    
    // Attach submit handlers with source tracking for analytics
    if (waitlistBarForm) {
        waitlistBarForm.addEventListener('submit', (e) => handleWaitlistSubmit(e, 'waitlistBarEmail', null, 'header_bar'));
    }
    
    if (waitlistMainForm) {
        waitlistMainForm.addEventListener('submit', (e) => handleWaitlistSubmit(e, 'waitlistMainEmail', 'waitlistMainMessage', 'main_cta'));
    }
    
    if (footerWaitlistForm) {
        footerWaitlistForm.addEventListener('submit', (e) => handleWaitlistSubmit(e, 'footerWaitlistEmail', 'footerWaitlistMessage', 'footer'));
    }
    
    if (waitlistPopupForm) {
        waitlistPopupForm.addEventListener('submit', (e) => handleWaitlistSubmit(e, 'waitlistPopupEmail', 'waitlistPopupMessage', 'popup'));
    }
}

async function handleWaitlistSubmit(event, emailInputId, messageElementId, source = 'unknown') {
    event.preventDefault();
    
    const emailInput = document.getElementById(emailInputId);
    const messageElement = messageElementId ? document.getElementById(messageElementId) : null;
    const email = emailInput.value.trim();
    
    if (!email) {
        if (messageElement) {
            showMessage(messageElement, 'Please enter your email', 'error');
        }
        return;
    }
    
    // Validate email
    if (!isValidEmail(email)) {
        if (messageElement) {
            showMessage(messageElement, 'Please enter a valid email', 'error');
        }
        return;
    }
    
    // Show loading state
    const submitBtn = event.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'Joining...';
    submitBtn.disabled = true;
    
    try {
        // Submit to Supabase with source tracking
        const result = await submitToWaitlist(email, source);
        
        if (result.success) {
            if (messageElement) {
                showMessage(messageElement, '🎉 You\'re on the list! We\'ll notify you when we launch.', 'success');
            } else {
                // Show beautiful success notification instead of alert
                showSuccessNotification(email);
            }
            emailInput.value = '';
            
            // Close popup if it's open
            const popup = document.getElementById('waitlistPopup');
            if (popup && popup.classList.contains('active')) {
                setTimeout(() => closeWaitlistPopup(), 1500);
            }
            
            // Store in localStorage to prevent showing popup again
            localStorage.setItem('virtupet_waitlist_joined', 'true');
        } else {
            if (result.duplicate) {
                if (messageElement) {
                    showMessage(messageElement, 'You\'re already on the waitlist! 🐾', 'success');
                } else {
                    showSuccessNotification(email, true);
                }
            } else {
                throw new Error(result.error || 'Failed to join waitlist');
            }
        }
    } catch (error) {
        console.error('Waitlist error:', error);
        if (messageElement) {
            showMessage(messageElement, 'Something went wrong. Please try again.', 'error');
        } else {
            alert('Something went wrong. Please try again.');
        }
    } finally {
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
    }
}

async function submitToWaitlist(email, source = 'unknown') {
    try {
        console.log('Submitting to waitlist:', { email, source, url: WAITLIST_API_URL });
        
        // Call Netlify serverless function (keys are secure on server)
        const response = await fetch(WAITLIST_API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: email,
                source: source
            })
        });

        console.log('Response status:', response.status);
        
        const result = await response.json();
        console.log('Response data:', result);

        if (!response.ok) {
            console.error('Server error:', result);
            throw new Error(result.error || 'Failed to join waitlist');
        }

        // Handle duplicate email
        if (result.duplicate) {
            return { success: false, duplicate: true };
        }

        return { success: true };
    } catch (error) {
        console.error('Waitlist error:', error);
        
        // Fallback to localStorage if function fails (for development/testing)
        console.warn('📧 Falling back to localStorage (function unavailable):', email, 'Source:', source);
        
        const waitlist = JSON.parse(localStorage.getItem('virtupet_waitlist') || '[]');
        
        if (waitlist.some(entry => entry.email === email)) {
            return { success: false, duplicate: true };
        }
        
        waitlist.push({
            email: email,
            source: source,
            timestamp: new Date().toISOString()
        });
        localStorage.setItem('virtupet_waitlist', JSON.stringify(waitlist));
        
        return { success: true };
    }
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showMessage(element, message, type) {
    element.textContent = message;
    element.className = `${element.className.split(' ')[0]} ${type}`;
    
    // Clear message after 5 seconds
    setTimeout(() => {
        element.textContent = '';
        element.className = element.className.split(' ')[0];
    }, 5000);
}

function showSuccessNotification(email, isDuplicate = false) {
    // Remove any existing notification
    const existingNotification = document.getElementById('waitlist-success-notification');
    if (existingNotification) {
        existingNotification.remove();
    }
    
    // Create notification element
    const notification = document.createElement('div');
    notification.id = 'waitlist-success-notification';
    notification.className = 'success-notification';
    
    notification.innerHTML = `
        <div class="success-notification-content">
            <div class="success-icon">
                <svg viewBox="0 0 50 50" xmlns="http://www.w3.org/2000/svg">
                    <circle class="success-circle" cx="25" cy="25" r="23" fill="none" stroke="currentColor" stroke-width="2"/>
                    <path class="success-checkmark" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" d="M14 27l7 7 14-14"/>
                </svg>
            </div>
            <div class="success-text">
                <h3>${isDuplicate ? 'Already on the list!' : 'Welcome to VirtuPet!'}</h3>
                <p>${isDuplicate ? 'We already have your email. We\'ll notify you when we launch on iOS!' : 'You\'re on the waitlist! We\'ll send you an email when VirtuPet launches on iOS.'}</p>
                ${!isDuplicate ? `<div class="success-email">${email}</div>` : ''}
                <a href="https://instagram.com/virtupetapp" target="_blank" class="success-instagram">
                    <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                    </svg>
                    Follow @virtupetapp for updates
                </a>
            </div>
            <button class="success-close" onclick="this.parentElement.parentElement.remove()">×</button>
        </div>
    `;
    
    // Add to page
    document.body.appendChild(notification);
    
    // Trigger animation
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    // Don't auto-remove - user must click X to close
}

/* ======================================
   WAITLIST POPUP
   ====================================== */
function initWaitlistPopup() {
    const popup = document.getElementById('waitlistPopup');
    const closeBtn = document.getElementById('waitlistPopupClose');
    
    if (!popup) return;
    
    // Check for test parameter to reset popup (for development) - FIRST!
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('resetPopup') === '1') {
        sessionStorage.removeItem('virtupet_popup_shown');
        localStorage.removeItem('virtupet_waitlist_joined');
        console.warn('🔄 Popup storage reset for testing');
    }
    
    // Close popup handlers
    if (closeBtn) {
        closeBtn.addEventListener('click', closeWaitlistPopup);
    }
    
    // Close on overlay click
    popup.addEventListener('click', (e) => {
        if (e.target === popup) {
            closeWaitlistPopup();
        }
    });
    
    // Close on escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && popup.classList.contains('active')) {
            closeWaitlistPopup();
        }
    });
    
    // Show popup after 10 seconds OR on scroll past 40% (if user hasn't already joined)
    const hasJoined = localStorage.getItem('virtupet_waitlist_joined');
    const hasSeenPopup = sessionStorage.getItem('virtupet_popup_shown');
    
    console.warn('📋 Popup state - hasJoined:', hasJoined, 'hasSeenPopup:', hasSeenPopup);
    
    if (!hasJoined && !hasSeenPopup) {
        console.warn('⏱️ Setting up popup timer (22 seconds)...');
        
        // Timer trigger
        const popupTimer = setTimeout(() => {
            openWaitlistPopup();
            sessionStorage.setItem('virtupet_popup_shown', 'true');
        }, 22000); // 22 seconds
        
        // Scroll trigger (40% of page)
        const scrollHandler = () => {
            const scrollPercent = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
            if (scrollPercent > 40) {
                clearTimeout(popupTimer);
                openWaitlistPopup();
                sessionStorage.setItem('virtupet_popup_shown', 'true');
                window.removeEventListener('scroll', scrollHandler);
            }
        };
        window.addEventListener('scroll', scrollHandler);
    }
}

function openWaitlistPopup() {
    const popup = document.getElementById('waitlistPopup');
    console.warn('🚀 Opening waitlist popup...', popup ? 'found' : 'not found');
    if (popup) {
        popup.classList.add('active');
        document.body.style.overflow = 'hidden';
        console.warn('✅ Popup is now active!');
    }
}

function closeWaitlistPopup() {
    const popup = document.getElementById('waitlistPopup');
    if (popup) {
        popup.classList.remove('active');
        document.body.style.overflow = '';
    }
}

