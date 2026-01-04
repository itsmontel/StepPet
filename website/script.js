/* ======================================
   VirtuPet Website JavaScript
   Animations, Interactivity, and Magic
   ====================================== */

document.addEventListener('DOMContentLoaded', () => {
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
   HERO PET CAROUSEL
   ====================================== */
function initHeroPetCarousel() {
    const pets = document.querySelectorAll('.hero-pet');
    let currentPet = 0;
    
    setInterval(() => {
        pets[currentPet].classList.remove('active');
        currentPet = (currentPet + 1) % pets.length;
        pets[currentPet].classList.add('active');
    }, 3000);
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
    // Feature cards
    observeElements('.feature-card', (entry) => {
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

